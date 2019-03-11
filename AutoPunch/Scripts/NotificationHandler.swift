//
//  NotificationHandler.swift
//  AutoPunch
//
//  Created by Kieran Sherman on 3/10/19.
//  Copyright © 2019 Kieran Sherman. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationHandler {
    
    //requests to allow notifications
    func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in})
    }
    
    //generates a notification
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
