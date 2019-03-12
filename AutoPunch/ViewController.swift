//
//  ViewController.swift
//  AutoPunch
//
//  Created by Kieran Sherman on 3/5/19.
//  Copyright © 2019 Kieran Sherman. All rights reserved.
//

import UIKit
import WebKit
import UserNotifications

class ViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var authorizeButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var clockSwitch: UISwitch!
    @IBOutlet weak var punchSwitch: UISwitch!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var updateLabel: UILabel!
    @IBOutlet weak var punchSwitchLabel: UILabel!
    @IBOutlet weak var notificationSwitchLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!
    
    private var loadCount = 0
    private let MAXLOAD = 4
    private var developerModeCount = 0
    private var isDeveloperMode = UserDefaults.standard.bool(forKey: "developer")
    
    private var nH:NotificationHandler?
    private var jS:JavaScriptHandler?
    
    //does on load
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
        
        UserDefaults.standard.register(defaults: ["punch" : true])
        
        nH = NotificationHandler(viewController: self)
        jS = JavaScriptHandler(viewController: self, notificationHandler: nH!)
        
        passwordText.delegate = self
        webView.navigationDelegate = self
        
        let username = UserDefaults.standard.string(forKey: "username")
        let password = UserDefaults.standard.string(forKey: "password")
        if (username != nil && password != nil)
        {
            usernameText.text = username
            passwordText.text = password
            
            showTools()
        }
        
        if(isDeveloperMode) {
            showDevTools()
        }
        
        //request access to notifications
        nH?.requestNotificationAccess()
    }
    
    //handles if a notification was accepted or declined
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if (response.actionIdentifier == "PUNCH_IN") {
            clockSwitch.isOn = true
            powerButtonPressed(self)
        } else if (response.actionIdentifier == "PUNCH_OUT") {
            clockSwitch.isOn = false
            powerButtonPressed(self)
        }
    }
    
    //updates various elements of the UI for a "prettier" look
    func updateUI() {
        usernameText.attributedPlaceholder = NSAttributedString(string: "username", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        passwordText.attributedPlaceholder = NSAttributedString(string: "password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        authorizeButton.layer.cornerRadius = 4
        resetButton.layer.cornerRadius = 4
    }
    
    //when the user presses the title (enabling/disabling dev mode)
    @IBAction func titlePressed(_ sender: Any) {
        developerModeCount += 1
        
        if(developerModeCount >= 3) {
            if(isDeveloperMode) {
                hideDevTools()
            } else {
                showDevTools()
            }
            
            isDeveloperMode = !isDeveloperMode
            developerModeCount = 0
            
            UserDefaults.standard.set(isDeveloperMode, forKey: "developer")
        }
    }
    
    //when the user toggles the punch switch (developer)
    @IBAction func punchSwitchToggled(_ sender: Any) {
        setUserDefaults()
    }
    
    //when the user toggles the clock switch
    @IBAction func clockSwitchToggled(_ sender: Any) {
        setUserDefaults()
    }
    
    //changes whether or not to display notifications
    @IBAction func notificationSwitchToggled(_ sender: Any) {
        if(notificationSwitch.isOn) {
            nH?.setTimedNotifications()
        } else {
            nH?.clearTimedNotifications()
        }
        
        setUserDefaults()
    }
    
    //when the user presses the authorize button
    @IBAction func authorizePressed(_ sender: Any) {
        setUserDefaults()
        hideKeyboard()
        showTools()
    }
    
    //when the user presses the reset button
    @IBAction func resetPressed(_ sender: Any) {
        clearUserDefaults()
        
        usernameText.text = ""
        passwordText.text = ""
    }
    
    //when the user presses the power button
    @IBAction func powerButtonPressed(_ sender: Any) {
        webView.isHidden = false
        
        let url = URL(string: "https://tlcmobile.bestbuy.com/mobileClock/")
        webView.load(URLRequest(url: url!))
    }
    
    //handles when a webpage loads
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadCount += 1
        
        if (loadCount == 1) {
            updateLabel.text = "logging in to TLC..."
            
            jS?.login(usernameText.text!, passwordText.text!)
        } else if (loadCount == 2) {
            jS?.setPunch(punch: punchSwitch.isOn)
            
            if(clockSwitch.isOn) {
                updateLabel.text = "punching in to TLC..."
                
                jS?.punchIn()
            } else {
                updateLabel.text = "punching out of TLC..."
                
                jS?.punchOut()
            }
            
            if(!punchSwitch.isOn) {
                loadCount += 1
                jS?.logout()
            }
        } else if (loadCount == 3) {
            updateLabel.text = "logging out of TLC..."
            
            jS?.logout()
        } else if (loadCount >= MAXLOAD) {
            updateLabel.text = ""
            webView.isHidden = true
            
            let url = URL(string: "https://tlcmobile.bestbuy.com/mobileClock/")
            webView.load(URLRequest(url: url!))
            
            clockSwitch.isOn = !clockSwitch.isOn
            loadCount = -1
            
            setUserDefaults()
        }
    }
    
    //handles when a textField is done editing
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideKeyboard()
        return true
    }
    
    //hides the on-screen keyboard
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    //executes javascript within the webView
    public func executeJavaScript(script: String) {
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    //shows the standard tools
    func showTools() {
        authorizeButton.isHidden = true
        resetButton.isHidden = false
        powerButton.isHidden = false
        clockSwitch.isHidden = false
        
        clockSwitch.isOn = UserDefaults.standard.bool(forKey: "clock")
    }
    
    //shows the dev tools
    func showDevTools() {
        punchSwitch.isHidden = false
        punchSwitchLabel.isHidden = false
        notificationSwitch.isHidden = false
        notificationSwitchLabel.isHidden = false
        
        punchSwitch.isOn = UserDefaults.standard.bool(forKey: "punch")
        notificationSwitch.isOn = UserDefaults.standard.bool(forKey: "notifications")
    }
    
    //hides the standard tools
    func hideTools() {
        authorizeButton.isHidden = false
        resetButton.isHidden = true
        powerButton.isHidden = true
        clockSwitch.isHidden = true
    }
    
    //hides the dev tools
    func hideDevTools() {
        punchSwitch.isHidden = true
        punchSwitchLabel.isHidden = true
        notificationSwitch.isHidden = true
        notificationSwitchLabel.isHidden = true
    }
    
    //sets user defaults
    func setUserDefaults() {
        UserDefaults.standard.set(usernameText.text, forKey: "username")
        UserDefaults.standard.set(passwordText.text, forKey: "password")
        UserDefaults.standard.set(clockSwitch.isOn, forKey: "clock")
        UserDefaults.standard.set(punchSwitch.isOn, forKey: "punch")
        UserDefaults.standard.set(notificationSwitch.isOn, forKey: "notifications")
    }
    
    //clears the saved user defaults
    func clearUserDefaults() {
        UserDefaults.standard.set(nil, forKey: "username")
        UserDefaults.standard.set(nil, forKey: "password")
        UserDefaults.standard.set(true, forKey: "clock")
        UserDefaults.standard.set(true, forKey: "punch")
        UserDefaults.standard.set(false, forKey: "notifications")
        UserDefaults.standard.set(false, forKey: "developer")
        
        hideTools()
        hideDevTools()
    }
}
