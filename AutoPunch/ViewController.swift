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

class ViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate {
    
    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var authorizeButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var clockSwitch: UISwitch!
    @IBOutlet weak var punchSwitchLabel: UILabel!
    @IBOutlet weak var punchSwitch: UISwitch!
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var webView: WKWebView!
    
    public var loadCount = 0
    private let MAXLOAD = 4
    private var developerMode = 0
    
    private var nH:NotificationHandler?
    private var jS:JavaScriptHandler?
    
    //does on load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nH = NotificationHandler()
        jS = JavaScriptHandler(viewController: self)
        
        passwordText.delegate = self
        webView.navigationDelegate = self
        
        let username = UserDefaults.standard.string(forKey: "username")
        let password = UserDefaults.standard.string(forKey: "password")
        clockSwitch.isOn = UserDefaults.standard.bool(forKey: "clock")
        
        if (username != nil && password != nil)
        {
            usernameText.text = username
            passwordText.text = password
            
            showTools()
        }
        
        if(UserDefaults.standard.bool(forKey: "developer")) {
            showDevTools()
        }
        
        //request access to notifications
        nH?.requestNotificationAccess()
    }
    
    //when the user presses the title (enabling dev mode)
    @IBAction func titlePressed(_ sender: Any) {
        developerMode += 1
        
        if(developerMode >= 3) {
            showDevTools()
            UserDefaults.standard.set(true, forKey: "developer")
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
            jS?.login(usernameText.text!, passwordText.text!)
        } else if (loadCount == 2) {
            jS?.setPunch(punch: punchSwitch.isOn)
            
            if(clockSwitch.isOn) {
                jS?.punchIn()
            } else {
                jS?.punchOut()
            }
            
            if(!punchSwitch.isOn) {
                loadCount += 1
                jS?.logout()
            }
        } else if (loadCount == 3) {
            jS?.logout()
        } else if (loadCount >= MAXLOAD) {
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
    
    //sets user defaults
    func setUserDefaults() {
        UserDefaults.standard.set(usernameText.text, forKey: "username")
        UserDefaults.standard.set(passwordText.text, forKey: "password")
        UserDefaults.standard.set(clockSwitch.isOn, forKey: "clock")
        UserDefaults.standard.set(punchSwitch.isOn, forKey: "punch")
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
    }
    
    //shows the dev tools
    func showDevTools() {
        punchSwitch.isHidden = false
        punchSwitchLabel.isHidden = false
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
    }
    
    //clears the saved user defaults
    func clearUserDefaults() {
        UserDefaults.standard.set(nil, forKey: "username")
        UserDefaults.standard.set(nil, forKey: "password")
        UserDefaults.standard.set(true, forKey: "clock")
        UserDefaults.standard.set(true, forKey: "punch")
        UserDefaults.standard.set(false, forKey: "developer")
        
        hideTools()
        hideDevTools()
    }
}
