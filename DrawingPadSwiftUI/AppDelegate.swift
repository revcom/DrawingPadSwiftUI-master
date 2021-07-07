//
//  AppDelegate.swift
//  DrawingPadSwiftUI
//
//  Created by Martin Mitrevski on 20.07.19.
//  Copyright © 2019 Mitrevski. All rights reserved.
//

import UIKit
import CloudKit
import SwiftUI

let updates = CloudUpdates()

@main
struct SwiftUIApp: App {

    // inject into SwiftUI life-cycle via adaptor !!!
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(updates: updates)
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //MARK: - Setup and Handle remote notifications from iCloud database
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UIApplication.shared.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print ("✅ Registered for remote notifications")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print ("🔴 Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print ("Remote notification received...")
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            if notification.notificationType == .query {
                let queryNotification = notification as! CKQueryNotification
                guard let recordID = queryNotification.recordID  else { print ("🔴 Bad recordID in notfication"); return }

                switch queryNotification.queryNotificationReason {
                    case .recordCreated:
                        print ("Record created: \(recordID)")
                        updates.recordsToUpdate.append(recordID)
                        updates.didUpdate = true
                    case .recordUpdated:
                        print ("Record updated: \(recordID)")
                    case .recordDeleted:
                        print ("Record deleted: \(recordID)")
                    @unknown default:
                        print ("Unknown iCloud notification type")
                }
            }
            completionHandler(.newData)
            return
        }

    }


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

class CloudUpdates: ObservableObject {
    @Published var didUpdate = false
    var recordsToUpdate: [CKRecord.ID] = []
    
    init() {
        print ("CloudUpdates created")
    }
}

