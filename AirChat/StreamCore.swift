//
//  StreamCore.swift
//  AirChat
//
//  Created by Vojta on 18/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CoreData

class ChatClient {
    
    // MARK:  -------------------- -------------------- Public -------------------- --------------------
    
    /// The main context for UI updates (read-only)
    var readContext: NSManagedObjectContext { persistentContainer.viewContext }
    
    var currentUser: User
    
    /// Subscribe to this notification center to receive incoming server events
    let eventNotificationCenter = NotificationCenter()
    
    /// Safely perform model changes
    func write(_ actions: @escaping (NSManagedObjectContext) -> Void) {
        writableContext.perform {
            actions(self.writableContext)
            do {
                try self.writableContext.save()
            } catch {
                print("Error saving changes: \(error.localizedDescription)")
            }
        }
    }
    
    /// Creates a new client
    init(currentUser: User = .init(name: "Vojta")) {
        self.currentUser = currentUser
        
        let syncContext = persistentContainer.newBackgroundContext()
        syncContext.automaticallyMergesChangesFromParent = true
        syncContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        syncWorker = SyncWorker(context: syncContext, notificationCenter: eventNotificationCenter, currentUser: currentUser)
        loadDummyData()
    }
    
    
    // MARK:  -------------------- -------------------- Private -------------------- --------------------
    
    var syncWorker: SyncWorker!

    lazy var writableContext: NSManagedObjectContext = {
        let context = self.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreModel")
        
        // At this point we store the db in a throw-away location and always start with fresh data
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
        return container
    }()
    
    func loadDummyData() {
        write { context in
            let bahadir = User(name: "Bahadir")

            var channel = Channel(name: "Chat with Bahadir")
            channel.members = [self.currentUser, bahadir]
            
            let messages = [
                Message(text: "Hey there!", user: bahadir, channelId: channel.id),
                Message(text: "What's up?", user: bahadir, channelId: channel.id),
            ]

            messages.forEach { $0.save(to: context) }
            channel.lastMessageTimestamp = messages.map { $0.timestamp }.min()
            channel.save(to: context)
        }
    }
}

// Note: This won't be NSObject in the production code
class Reference: NSObject {
    init(client: ChatClient) {
        self.client = client
    }
    
    let client: ChatClient
}

extension Reference {
    var currentUser: User { client.currentUser }
}

private let cacheDirectoryURL = try! FileManager.default.url(
    for: .cachesDirectory,
    in: .userDomainMask,
    appropriateFor: nil,
    create: false
)

// MARK: - Models

enum ChannelType: Hashable {
    case unknown, livestream, messaging, team, gaming, commerce
    case custom(String)
}

struct Channel: Hashable, Identifiable {
    var id: Id ; typealias Id = String
    
    let name: String
    
    var members: Set<User> = []
    var type: ChannelType = .messaging
    
    var lastMessageTimestamp: Date?
    var lastMessage: Message?
    var timestamp: Date
    
    init(name: String, id: Id = UUID().uuidString, timestamp: Date = .init()) {
        self.name = name
        self.id = id
        self.timestamp = timestamp
    }
}

struct Member: Hashable { }

struct Message: Hashable {
    enum State: Int16, Hashable {
        case pendingSend
        case pendingDelete
    }
    
    var additionalState: State?
    
    typealias Id = String
    var id: Id = UUID().uuidString
    let text: String
    let user: User
    
    var timestamp: Date = .init()
    var channelId: Channel.Id?
}

struct CurrentUser { }

struct User: Hashable {
    typealias Id = String
    let id: Id
    let name: String
    
    init(name: String, id: Id = UUID().uuidString) {
        self.name = name
        self.id = id
    }
}

struct QueryOptions { }
struct Pagination { }

protocol ChannelExtraDataCodable: Codable { }

// ???????????
struct Filter<Base> { }

func ~=<Base, T, C: Collection>(lhs: KeyPath<Base, C>, rhs: T)  -> Filter<Base> where C.Element == T { .init() }

func && <Base>(lhs: Filter<Base>, rhs: Filter<Base>) -> Filter<Base> { .init() }

func == <Base, T>(lhs: KeyPath<Base, T>, rhs: T) -> Filter<Base> { .init() }

//func == <T>(las:  res:) -> Filter { .init() }













protocol Event { }

protocol ChannelEvent: Event { }
protocol MemberEvent: Event { }

protocol TypingEvent: Event { }

struct TypingStarted: TypingEvent {
    let user: User
}

struct TypingStopped: TypingEvent {
    let user: User
}

extension String: Error { }


// WIP!
enum Change<T> {
    case added(_ item: T)
    case updated(_ item: T)
    case moved(_ item: T)
    case removed(_ item: T)
}
