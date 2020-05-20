//
//  AppDelegate.swift
//  AirChat
//
//  Created by Vojta on 14/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let client = Client()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let navVC = UINavigationController()
        
        let filter: Filter = \.type == .messaging && \.members ~= client.currentUser
        let query = ChannelListReference.Query(filter: filter)
        
        let channelListRef = client.channelListReference(query: query)
        let channelListVC = ChatListViewController(reference: channelListRef) { selectedChatId in
            let chatVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ChatViewController") as! ChatViewController
            chatVC.channelRef = client.channelReference(id: selectedChatId)
            navVC.show(chatVC, sender: nil)
        }
        
        navVC.setViewControllers([channelListVC], animated: false)
    
        window?.rootViewController = navVC
        window?.makeKeyAndVisible()
        
        return true
    }
}

