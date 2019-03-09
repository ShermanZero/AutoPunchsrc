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
    
    @IBOutlet weak var powerButton: UIButton!
    @IBOutlet weak var clockSwitch: UISwitch!
    @IBOutlet weak var punchSwitch: UISwitch!
    @IBOutlet weak var authorizeButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var punchSwitchLabel: UILabel!
    
    @IBOutlet weak var webView: WKWebView!
    
    var loadCount = 0
    let MAXLOAD = 4
    var punch = true
    
    var developerMode = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        passwordText.delegate = self
        webView.navigationDelegate = self
        
        let username = UserDefaults.standard.object(forKey: "username")
        let password = UserDefaults.standard.object(forKey: "password")
        let clock : Bool = UserDefaults.standard.bool(forKey: "clock")
        clockSwitch.isOn = clock
        
        if ((username as? String) != nil) && ((password as? String) != nil)
        {
            usernameText.text = username as? String
            passwordText.text = password as? String
            
            show()
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in})
    }
    
    @IBAction func titlePressed(_ sender: Any) {
        developerMode += 1
        
        if(developerMode >= 3) {
            showDevTools()
        }
    }
    
    @IBAction func punchSwitchToggled(_ sender: Any) {
        punch = punchSwitch.isOn
    }
    
    @IBAction func authorizePressed(_ sender: Any) {
        setUserDefaults()
        hideKeyboard()
        show()
    }
    
    @IBAction func resetPressed(_ sender: Any) {
        clearSaved()
        
        usernameText.text = ""
        passwordText.text = ""
    }
    
    @IBAction func clockToggled(_ sender: Any) {
        setUserDefaults()
    }
    
    @IBAction func powerButtonPressed(_ sender: Any) {
        webView.isHidden = false
        
        let url = URL(string: "https://tlcmobile.bestbuy.com/mobileClock/")
        webView.load(URLRequest(url: url!))
    }
    
    func showDevTools() {
        punchSwitch.isHidden = false
        punchSwitchLabel.isHidden = false
    }
    
    func setUserDefaults() {
        UserDefaults.standard.set(usernameText.text, forKey: "username")
        UserDefaults.standard.set(passwordText.text, forKey: "password")
        UserDefaults.standard.set(clockSwitch.isOn, forKey: "clock")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideKeyboard()
        return true
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadCount += 1
       
        webView.evaluateJavaScript("document.body.innerHTML") { (string, error) in print(string!) }
        
        if (loadCount == 1) {
            if (!login()) {
                loadCount = MAXLOAD
            }
        } else if (loadCount == 2) {
            if(clockSwitch.isOn) {
                punchIn()
            }
            else {
                punchOut()
            }
            
            if(!punch) {
                loadCount += 1
                logout()
            }
        } else if (loadCount == 3) {
            logout()
        } else if (loadCount >= MAXLOAD) {
            webView.isHidden = true
            
            let url = URL(string: "https://tlcmobile.bestbuy.com/mobileClock/")
            webView.load(URLRequest(url: url!))
            
            clockSwitch.isOn = !clockSwitch.isOn
            setUserDefaults()
            loadCount = -1
        }
    }
    
    func show() {
        authorizeButton.isHidden = true
        resetButton.isHidden = false
        powerButton.isHidden = false
        clockSwitch.isHidden = false
    }
    
    func hide() {
        authorizeButton.isHidden = false
        resetButton.isHidden = true
        powerButton.isHidden = true
        clockSwitch.isHidden = true
    }
    
    func clearSaved() {
        UserDefaults.standard.set(nil, forKey: "username")
        UserDefaults.standard.set(nil, forKey: "password")
        
        hide()
    }
    
    func login() -> Bool {
        doJavaScript(script: "var login=document.getElementById(\"loginField\"); login.value=\"a" + usernameText.text! + "\";")
        doJavaScript(script: "var password=document.getElementById(\"passwordField\"); password.value=\"" + passwordText.text! + "\";")
        doJavaScript(script: "var submit=document.getElementById(\"submitButton\"); submit.click();")
    
        return true
    }
    
    func punchIn() {
        if(punch) {
            doJavaScript(script: "var punchIn=document.getElementsByName(\"Clock_On_Button\");punchIn[0].click();")
        }
        
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        let body = "AutoPunch punched-in for you at \(hour):\(minutes)!"
        
        generateNotification(title: "Punch-in successful!", body: body)
    }
    
    func punchOut() {
        if(punch) {
            doJavaScript(script: "var punchOut=document.getElementsByName(\"Clock_Off_Button\");punchOut[0].click();")
        }

        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        let body = "AutoPunch punched-out for you at \(hour):\(minutes)!"
        
        generateNotification(title: "Punch-out successful!", body: body)
    }
    
    func logout() {
        doJavaScript(script: "var logout=document.getElementsByName(\"Logout_Button\");logout[0].click();")
    }
    
    func doJavaScript(script: String) {
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func generateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        
        content.title = title
        content.body = body
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
