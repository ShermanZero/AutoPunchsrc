//
//  NotificationHandler.swift
//  AutoPunch
//
//  Created by Kieran Sherman on 3/10/19.
//  Copyright © 2019 Kieran Sherman. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class NotificationHandler {
    
    private var vC: ViewController?
    private var notificationsAllowed: Bool = false
    
    init(viewController: ViewController) {
        self.vC = viewController
        
        notificationsAllowed = UserDefaults.standard.bool(forKey: "notificationsAllowed")
    }
    
    //requests to allow notifications
    public func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in
                if(didAllow) {
                    self.notificationsAllowed = true
                    UserDefaults.standard.set(self.notificationsAllowed, forKey: "notificationsAllowed")
                    
                    //sets the delegate to the ViewController
                    UNUserNotificationCenter.current().delegate = self.vC
            
                    //sets up the actionable notifications
                    self.setActionableNotifications()
                }
            })
    }
    
    //sets up timed notifications
    public func setTimedNotifications() {
        if(!notificationsAllowed) {
            return
        }
        
        //clears any timed notifications
        clearTimedNotifications()
        
        //sets up timed notifications for morning
        generateTimedNotification(hour: 7, minute: 45, weekdays: [3, 4, 5, 7], body: "It's time to punch-in!")
        
        //sets up timed notifications for afternoon
        generateTimedNotification(hour: 17, minute: 45, weekdays: [3, 4, 5, 7], body: "It's time to punch-out!")
    }
    
    //clears timed notifications
    public func clearTimedNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
    
    //generates a notification
    public func generateNotification(title: String, body: String, category: String? = nil, timed: Bool? = false) -> UNMutableNotificationContent? {
        if (!notificationsAllowed) {
            return nil
        }
        
        let content = UNMutableNotificationContent()
        
        content.title = title
        content.body = body
        
        if (category != nil) {
            content.categoryIdentifier = category!
        }
        
        content.badge = 1

        if (timed == false) {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
        
        return content
    }
    
    //set actionable notifcations with prompts
    private func setActionableNotifications() {
        if(!notificationsAllowed) {
            return
        }
        
        let acceptAction = UNNotificationAction(identifier: "PUNCH_IN", title: "Punch-In", options: UNNotificationActionOptions.foreground)
        let declineAction = UNNotificationAction(identifier: "PUNCH_OUT", title: "Punch-Out", options: UNNotificationActionOptions.foreground)
        
        let category = UNNotificationCategory(identifier: "PUNCH_REQUEST", actions: [acceptAction, declineAction], intentIdentifiers: [], options: [])
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([category])
    }
    
    //sets up timed notifications
    private func generateTimedNotification(hour: Int, minute: Int, weekdays: [Int], body: String) {
        if(!notificationsAllowed) {
            return
        }
        
        for weekday in weekdays {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = weekday
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let content = generateNotification(title: "AutoPunch", body: body, category: "PUNCH_REQUEST", timed: true)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content!, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
}
