//
//  ChannelReference.swift
//  AirChat
//
//  Created by Vojta on 21/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit
import Combine
import CoreData

extension ChatClient {
    func channelReference(id: Channel.Id) -> ChannelReference {
        ChannelReference(client: self, channelId: id)
    }
}

/// An object representing a channel. You can use it to observe channel changes and modify its content.
///
/// - Note: It's completely safe to have multiple references to the same channel if your scenario requires it.
///
class ChannelReference: Reference {
    
    // MARK:  -------------------- -------------------- Public -------------------- --------------------

    let channelId: Channel.Id
    
    private(set) lazy var channel: Channel = { fatalError("Call `startUpdating` first") }()
    private(set) lazy var messages: [Message] = { fatalError("Call `startUpdating` first") }()
    private(set) lazy var members: [Member] = { fatalError("Call `startUpdating` first") }()
    private(set) lazy var watchers: [Member] = { fatalError("Call `startUpdating` first") }()
    
    weak var delegate: ChannelReferenceDelegate?

    /// Synchronously loads the data for the referenced object form the local cache and starts observing its changes.
    ///
    /// It also anynchronously fetches the data from the servers. If the remote data differs from the locally cached one,
    /// `ChannelReference` uses the `delegate` methods to inform about the changes.
    ///
    func startUpdating() {
        channel = Channel(id: channelId, context: client.persistentContainer.viewContext)
        
        fetchResultsController.delegate = self
        try! fetchResultsController.performFetch()
        
        self.messages = fetchResultsController.fetchedObjects!.map(Message.init)

        delegate?.willStartFetchingRemoteData(self)
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 2) {
            self.delegate?.didStopFetchingRemoteData(self, success: true)
        }
    }
    
    func send(message: Message) {
        client.write {
            var message = message
            message.additionalState = .pendingSend
            message.channelId = self.channelId
            
            var channel = Channel(id: self.channelId, context: $0)
            channel.lastMessageTimestamp = message.timestamp
            
            message.save(to: $0)
            channel.save(to: $0)
        }
    }
    
    func send(event: TypingEvent, completion: ((Error?) -> Void)? = nil) {  }
    
    func startWatchingChannel(options: QueryOptions, completion: (Error?) -> Void) {  }
    func stopWatchingChannel(options: QueryOptions, completion: (Error?) -> Void) {  }
    
    func load(pagination: Pagination, completion: (Error?) -> Void) {  }
    
    func delete(image: URL, completion: (Error?) -> Void) {  }
    func delete(file: URL, completion: (Error?) -> Void) {  }
    
    func delete(message: Message, completion: ((Error?) -> Void)?) {
        var message = message
        message.additionalState = .pendingDelete
        client.write { message.save(to: $0) }
        
        // simulate delete API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            let isFailure = Int.random(in: 0...2) == 2
            guard isFailure == false else {
                message.additionalState = nil
                self.client.write { message.save(to: $0) }
                completion?("Too many bugs...")
                return
            }
            
            self.client.write {
                $0.delete(MessageDTO.message(id: message.id, in: $0))
            }
        }
    }
    
    func hide(clearHistory: Bool = false, completion: (Error?) -> Void) {  }
    func show(completion: (Error?) -> Void) {  }
    
    func ban(member: Member, completion: (Error?) -> Void) {  }
    func add(members: Set<Member>, completion: (Error?) -> Void) {  }
    func remove(members: Set<Member>, completion: (Error?) -> Void) {  }
    
    func invite(members: Set<Member>, completion: (Error?) -> Void) {  }
    func acceptInvite(with message: Message? = nil, completion: (Error?) -> Void) {  }
    func rejectInvite(with message: Message? = nil, completion: (Error?) -> Void) {  }
    
    func markRead(completion: (Error?) -> Void) {  }
    func update(name: String? = nil,
                imageURL: URL? = nil,
                exatraData: ChannelExtraDataCodable? = nil,
                completion: (Error?) -> Void) {  }
    func delete(completion: (Error?) -> Void) {  }

    init(client: ChatClient, channelId: Channel.Id) {
        self.channelId = channelId
        super.init(client: client)
        
        client.eventNotificationCenter.addObserver(
            self,
            selector: #selector(handleNewEventNotification(_:)),
            name: .NewEventReceived,
            object: nil
        )
    }
    
    // MARK:  -------------------- -------------------- Private -------------------- --------------------
    
    private lazy var fetchResultsController: NSFetchedResultsController<MessageDTO> = {
        let request = Message.messagesForChannelFetchRequest(channelId: self.channelId)
        return .init(fetchRequest: request,
                     managedObjectContext: self.client.persistentContainer.viewContext,
                     sectionNameKeyPath: nil,
                     cacheName: nil)
    }()

    private var currentChanges: [Change<Message>]?
    
    @objc private func handleNewEventNotification(_ notification: Notification) {
        guard let event = notification.event else { return }
        
        if let event = event as? TypingEvent {
            delegate?.didReceiveTypingEvent(self, event: event)
        }
        if let event = event as? MemberEvent {
            delegate?.didReceiveMemeberEvent(self, event: event)
        }
        if let event = event as? ChannelEvent {
            delegate?.didReceiveChannelEvent(self, event: event)
        }
    }
    
    // ======= API to simulate functionality

    private func simulateTypingEvent(user: User) {
        delegate?.didReceiveTypingEvent(self, event: TypingStarted(user: user))
        
        let rnd = TimeInterval.random(in: 2...5)
        DispatchQueue.main.asyncAfter(deadline: .now() + rnd) {
            self.delegate?.didReceiveTypingEvent(self, event: TypingStopped(user: user))
            
            self.simulateReceivedMessage(user: user)
            
            let rnd = TimeInterval.random(in: 5...8)
            DispatchQueue.main.asyncAfter(deadline: .now() + rnd) {
                self.simulateTypingEvent(user: user)
            }
        }
    }
    
    private func simulateReceivedMessage(user: User) {
        let message = Message(text: Lorem.words(1...8), user: user)
        messages.append(message)
        delegate?.messagesChanged(self, changes: [.added(message)])
    }
}

extension ChannelReference: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         currentChanges = []
     }
     
     func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                     didChange anObject: Any,
                     at indexPath: IndexPath?,
                     for type: NSFetchedResultsChangeType,
                     newIndexPath: IndexPath?) {
         var change: Change<Message>?
         let message = Message(from: anObject as! MessageDTO)
         
         switch type {
         case .insert:
             change = .added(message)
         case .delete:
             change = .removed(message)
         case .move, .update:
             change = .updated(message)
         @unknown default:
             break
         }
         
         if let change = change {
             currentChanges!.append(change)
         }
     }

     func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         messages = fetchResultsController.fetchedObjects!.map(Message.init)
         delegate?.messagesChanged(self, changes: currentChanges!)
     }
}

// Old school delegate
protocol ChannelReferenceDelegate: AnyObject {
        
    func channelDataUpdated(_ reference: ChannelReference, data: Channel)
    func messagesChanged(_ reference: ChannelReference, changes: [Change<Message>])
    
    // With cool new options!
    @available(iOS 13, *)
    func messagesChanged(reference: ChannelReference, changes: NSDiffableDataSourceSnapshot<Never, Message>)
    
    
    func willStartFetchingRemoteData(_ reference: ChannelReference)
    func didStopFetchingRemoteData(_ reference: ChannelReference, success: Bool)
    
    func didReceiveChannelEvent(_ reference: ChannelReference, event: ChannelEvent)
    func didReceiveTypingEvent(_ reference: ChannelReference, event: TypingEvent)
    func didReceiveMemeberEvent(_ reference: ChannelReference, event: MemberEvent)
}

// Combine wrapper
@available(iOS 13, *)
extension ChannelReference {
    var channelDataPublisher: CurrentValueSubject<Channel, Never> { fatalError() }
    
    var messagesDiffableSnapshotPublisher: PassthroughSubject<NSDiffableDataSourceSnapshot<Never, Message>, Never> { fatalError() }
    var messagesChangesPublisher: PassthroughSubject<[Change<Message>], Never> { fatalError() }
    var fetchingRemoteDataActivityPublisher: PassthroughSubject<Bool, Never> { fatalError() }
    
    var channelEventsPublisher: PassthroughSubject<ChannelEvent, Never> { fatalError() }
    var typingEventsPublisher: PassthroughSubject<TypingEvent, Never> { fatalError() }
    var memeberEventsPublisher: PassthroughSubject<MemberEvent, Never> { fatalError() }
}


// SwiftUI wrapper
extension ChannelReference {
    @available(iOS 13, *)
    class Observable: ObservableObject {

        var channelEvents: PassthroughSubject<ChannelEvent, Never> { fatalError() }
        var typingEvents: PassthroughSubject<TypingEvent, Never> { fatalError() }
        var memeberEvents: PassthroughSubject<MemberEvent, Never> { fatalError() }
        
        @Published private(set) var channel: Channel
        @Published private(set) var messages: [Message]
        @Published private(set) var members: [Member]
        @Published private(set) var watchers: [Member]
        
        init(client: ChatClient, channelId: Channel.Id) {
            let ref = ChannelReference(client: client, channelId: channelId)
            ref.startUpdating() // TODO: listen for changes
            
            channel = ref.channel
            messages = ref.messages
            members = ref.members
            watchers = ref.watchers
        }
    }
}

// Default implementation for ChannelReferenceDelegate
extension ChannelReferenceDelegate {
    func channelDataUpdated(_ reference: ChannelReference, data: Channel) {}
    
    func messagesChanged(_ reference: ChannelReference, changes: [Change<Message>]) {}
    
    // With cool new options!
    @available(iOS 13, *)
    func messagesChanged(reference: ChannelReference, changes: NSDiffableDataSourceSnapshot<Never, Message>) {}
    
    
    func willStartFetchingRemoteData(_ reference: ChannelReference) {}
    func didStopFetchingRemoteData(_ reference: ChannelReference, success: Bool) {}
    
    func didReceiveChannelEvent(_ reference: ChannelReference, event: ChannelEvent) {}
    func didReceiveTypingEvent(_ reference: ChannelReference, event: TypingEvent) {}
    func didReceiveMemeberEvent(_ reference: ChannelReference, event: MemberEvent) {}
}
