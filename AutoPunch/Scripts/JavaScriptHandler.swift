//
//  JavaScriptHandler.swift
//  AutoPunch
//
//  Created by Kieran Sherman on 3/10/19.
//  Copyright © 2019 Kieran Sherman. All rights reserved.
//

import Foundation
import WebKit

class JavaScriptHandler {

    private var nH:NotificationHandler?
    private var vC:ViewController?
    private var punch:Bool = true
    
    init(viewController: ViewController, notificationHandler: NotificationHandler) {
        self.vC = viewController
        self.nH = notificationHandler
    }
    
    //sets whether or not to actually punch-in/out
    public func setPunch(punch: Bool) {
        self.punch = punch
    }
    
    //handles the login to TLC
    public func login(_ username: String, _ password: String) {
        relayJavaScript(javaScript: "var login=document.getElementById(\"loginField\"); login.value=\"a\(username)\";")
        relayJavaScript(javaScript: "var password=document.getElementById(\"passwordField\"); password.value=\"\(password)\";")
        relayJavaScript(javaScript: "var submit=document.getElementById(\"submitButton\"); submit.click();")
    }
    
    //handles the punch-in to TLC
    public func punchIn() {
        if(punch) {
            relayJavaScript(javaScript: "var punchIn=document.getElementsByName(\"Clock_On_Button\");punchIn[0].click();")
        }
        
        let time = getHourAndMinute()
        let body = "AutoPunch punched-in for you at \(time[0]):\(time[1])!"
        
        nH?.generateNotification(title: "Punch-in successful!", body: body)
    }
    
    //handles the punch-out of TLC
    public func punchOut() {
        if(punch) {
            relayJavaScript(javaScript: "var punchOut=document.getElementsByName(\"Clock_Off_Button\");punchOut[0].click();")
        }
        
        let time = getHourAndMinute()
        let body = "AutoPunch punched-out for you at \(time[0]):\(time[1])!"
        
        nH?.generateNotification(title: "Punch-out successful!", body: body)
    }
    
    //handles the logout of TLC, delaying by one second to show user punch
    public func logout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.relayJavaScript(javaScript: "var logout=document.getElementsByName(\"Logout_Button\");logout[0].click();")
        })
    }
    
    //returns the current hour and minute in an Integer array
    private func getHourAndMinute() -> [Int] {
        let date = Date()
        let calendar = Calendar.current
        
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        
        return [hour, minutes]
    }
    
    //relays javascript to execute back to the ViewController
    private func relayJavaScript(javaScript: String) {
        vC?.executeJavaScript(script: javaScript)
    }
}
