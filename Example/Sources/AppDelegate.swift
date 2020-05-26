//
//  AppDelegate.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 29/03/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatClient
import RxSwift
import RxCocoa

import UIKit
import StreamChatClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let config = Client.Config(apiKey: "b67pax5b2wdq", logOptions: .info)
        Client.configureShared(config)

        let userExtraData = UserExtraData(name: "Hidden band")
        Client.shared.set(user: User(id: "hidden-band-1", extraData: userExtraData),
                          token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiaGlkZGVuLWJhbmQtMSJ9.wNgIJ6oR8Z5qFdeLzsrEUfiovElpjEjjYBhU9U1HCTg")
        return true
    }
}

//
//@UIApplicationMain
//final class AppDelegate: UIResponder, UIApplicationDelegate {
//
//    var window: UIWindow?
//
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        ClientLogger.iconEnabled = true
//
//        let config = Client.Config(apiKey: "b67pax5b2wdq", logOptions: .info)
//        Client.configureShared(config)
//
//        let userExtraData = UserExtraData(name: "Hidden band")
//        Client.shared.set(user: User(id: "hidden-band-1", extraData: userExtraData),
//                          token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiaGlkZGVuLWJhbmQtMSJ9.wNgIJ6oR8Z5qFdeLzsrEUfiovElpjEjjYBhU9U1HCTg")
//        return true
//    }
//
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        print("🗞📱", "App did register for remote notifications with DeviceToken")
//
//        Client.shared.addDevice(deviceToken: deviceToken)
//    }
//
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("🗞❌", error)
//    }
//
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        print("🗞📮", userInfo)
//    }
//}
