//
//  SyncWorker.swift
//  AirChat
//
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import Foundation
import CoreData

/// Takes care of syncing between the local storage and backend
///
/// For example:
/// - Observes the storage and looks for messing pening send. Tries to send them and if succeeds, change the message status.
/// - Listens for backend events and handles them/forwards them to the client
///
class SyncWorker: NSObject, NSFetchedResultsControllerDelegate {
    
    let controller: NSFetchedResultsController<MessageDTO>
    let context: NSManagedObjectContext
    var currentUser: User
    
    let notificationCenter: NotificationCenter
    
    init(context: NSManagedObjectContext, notificationCenter: NotificationCenter, currentUser: User) {
        self.currentUser = currentUser
        self.context = context
        self.notificationCenter = notificationCenter
        
        let request = Message.messagesPendingSendFetchRequest()
        controller = .init(fetchRequest: request,
                           managedObjectContext: context,
                           sectionNameKeyPath: nil,
                           cacheName: nil)
    
        super.init()
        
        controller.delegate = self
        try! controller.performFetch()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == .insert, let messageDTO = anObject as? MessageDTO {
            var message = Message(from: messageDTO)
            print("👉 Sending message: \(message.text)")
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                self.context.perform {
                    message.additionalState = nil
                    message.save(to: self.context)
                    
                    print("✅ Sent message: \(message.text)")
                    
                    do {
                        if self.context.hasChanges {
                            try self.context.save()
                        }
                    } catch {
                        print(error)
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.simulateResponse(text: String(message.text.reversed()), channelId: message.channelId!)
                }
            }
        }
    }
    
    // ======= API to simulate functionality
    
    func simulateResponse(text: String, channelId: Channel.Id) {
        simulateEvent(event: TypingStarted(user: otherUser))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.simulateEvent(event: TypingStopped(user: otherUser))

            self.context.perform {
                let message = Message(text: text, user: otherUser, channelId: channelId)
                message.save(to: self.context)
                
                var channel = Channel(id: channelId, context: self.context)
                channel.lastMessageTimestamp = message.timestamp
                channel.save(to: self.context)
                
                do {
                    if self.context.hasChanges {
                        try self.context.save()
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func simulateEvent(event: Event) {
        notificationCenter.post(Notification(newEventReceived: event, sender: self))
    }
}

extension Notification.Name {
    static let NewEventReceived = Notification.Name("co.getStream.chat.core.new_event_received")
}

extension Notification {
    private static let eventKey = "co.getStream.chat.core.event_key"
    
    init(newEventReceived event: Event, sender: Any) {
        self.init(name: .NewEventReceived, object: sender, userInfo:  [Self.eventKey: event])
    }
    
    var event: Event? {
        userInfo?[Self.eventKey] as? Event
    }
}

// Dummy da
private let otherUser = User(name: "Bahadir")
