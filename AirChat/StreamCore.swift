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

//////////////////////////////////////////////////
///         Everything here is just mock
//////////////////////////////////////////////////

typealias Cancellable = Void

class Client {
    var currentUser: User = User(name: "Vojta")
    
    func channelReference(id: Channel.Id) -> ChannelReference {
        ChannelReference(client: self)
    }
}

class Reference {
    init(client: Client) {
        self.client = client
    }
    
    fileprivate let client: Client
}

extension Reference {
    var currentUser: User { client.currentUser }
}







// MARK: - Models

enum ChannelType {
    case unknown, livestream, messaging, team, gaming, commerce
    case custom(String)
}

struct Channel {
    typealias Id = String
    var id: Id { name }
    let name: String
    
    var members: [User] = []
    var type: ChannelType = .messaging
}

struct Member: Hashable { }

struct Message: Hashable {
    enum State: Hashable {
        case pendingSend
        case pendingDelete
    }
    
    var additionalState: State?
    
    typealias Id = String
    let id: Id = UUID().uuidString
    let text: String
    let user: User
}

struct CurrentUser { }

struct User: Hashable {
    typealias Id = String
    let id: Id = UUID().uuidString
    let name: String
}

struct QueryOptions { }
struct Pagination { }

protocol ChannelExtraDataCodable: Codable { }

class ChannelListReference {
    
}

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

















import CoreData

// MARK: - ======================== Channel reference ========================

class ChannelReference: Reference {
    
    override init(client: Client) {
        super.init(client: client)
        
        let rnd = TimeInterval.random(in: 5...10)
        DispatchQueue.main.asyncAfter(deadline: .now() + rnd) {
            self.simulateTypingEvent(user: self.bahadir)
        }
    }
    
    private(set) lazy var channel: Channel = { fatalError("Call `startUpdating` first") }()
    private(set) lazy var messages: [Message] = { fatalError("Call `startUpdating` first") }()
    private(set) lazy var members: [Member] = { fatalError("Call `startUpdating` first") }()
    private(set) lazy var watchers: [Member] = { fatalError("Call `startUpdating` first") }()
    
    weak var delegate: ChannelReferenceDelegate?
    
    /// Synchronously loads the data for the referenced object form the local cache and starts observing its changes.
    ///
    /// It also anynchronously fetches the data from the servers. If the remote data differs from the locally cached one,
    /// `ChannelReference` uses the `delegate` methods to inform about the changes.
    func startUpdating() {
        // Simulate local fetch
        let messages = initialMessages(currentUser: client.currentUser)
        
        channel = .init(name: "Chat with Bahadir")
        self.messages = Array(messages.prefix(3))
        members = []
        watchers = []

        delegate?.willStartFetchingRemoteData(self)
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 2) {
            self.delegate?.didStopFetchingRemoteData(self, success: true)
            let changes = messages[3...].map { Change.added($0) }
            self.messages = messages
            self.delegate?.messagesChanged(self, changes: changes)
        }
    }
    
    // MARK:: Actions
    
    func send(message: Message) -> Cancellable {
        var message = message
        message.additionalState = .pendingSend
        
        messages.append(message)
        delegate?.messagesChanged(self, changes: [.added(message)])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            message.additionalState = nil
            self.update(message: message)
            self.delegate?.messagesChanged(self,
                                           changes: [.updated(message)])
        }
    }
    
    private func update(message: Message) {
        let idx = messages.firstIndex(where: { $0.id == message.id })!
        messages[idx] = message
    }
    
    func send(event: TypingEvent, completion: ((Error?) -> Void)? = nil) -> Cancellable {  }
    
    func startWatchingChannel(options: QueryOptions, completion: (Error?) -> Void) -> Cancellable {  }
    func stopWatchingChannel(options: QueryOptions, completion: (Error?) -> Void) -> Cancellable {  }
    
    func load(pagination: Pagination, completion: (Error?) -> Void) -> Cancellable {  }
    
    func delete(image: URL, completion: (Error?) -> Void) -> Cancellable {  }
    func delete(file: URL, completion: (Error?) -> Void) -> Cancellable {  }
    
    func delete(message: Message, completion: ((Error?) -> Void)?) -> Cancellable {
        var message = message
        message.additionalState = .pendingDelete
        
        self.update(message: message)
        
        delegate?.messagesChanged(self, changes: [.updated(message)])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let isFailure = Int.random(in: 0...2) == 2
            guard isFailure == false else {
                message.additionalState = nil
                self.update(message: message)
                self.delegate?.messagesChanged(self, changes: [.updated(message)])
                completion?("Too many bugs...")
                return
            }
            
            self.messages.removeAll(where: { $0.id == message.id })
            self.delegate?.messagesChanged(self, changes: [.removed(message)])
        }
    }
    
    func hide(clearHistory: Bool = false, completion: (Error?) -> Void) -> Cancellable {  }
    func show(completion: (Error?) -> Void) -> Cancellable {  }
    
    func ban(member: Member, completion: (Error?) -> Void) -> Cancellable {  }
    func add(members: Set<Member>, completion: (Error?) -> Void) -> Cancellable {  }
    func remove(members: Set<Member>, completion: (Error?) -> Void) -> Cancellable {  }
    
    func invite(members: Set<Member>, completion: (Error?) -> Void) -> Cancellable {  }
    func acceptInvite(with message: Message? = nil, completion: (Error?) -> Void) -> Cancellable {  }
    func rejectInvite(with message: Message? = nil, completion: (Error?) -> Void) -> Cancellable {  }
    
    func markRead(completion: (Error?) -> Void) -> Cancellable {  }
    func update(name: String? = nil,
                imageURL: URL? = nil,
                exatraData: ChannelExtraDataCodable? = nil,
                completion: (Error?) -> Void) -> Cancellable {  }
    func delete(completion: (Error?) -> Void) -> Cancellable {  }

    
    // ======= API to simulate functionality

    let bahadir = User(name: "Bahadir")
    
    func simulateTypingEvent(user: User) {
        delegate?.didReceiveTypingEvent(self, event: TypingStarted(user: user), metadata: .init())
        
        let rnd = TimeInterval.random(in: 2...5)
        DispatchQueue.main.asyncAfter(deadline: .now() + rnd) {
            self.delegate?.didReceiveTypingEvent(self, event: TypingStopped(user: user), metadata: .init())
            
            self.simulateReceivedMessage(user: user)
            
            let rnd = TimeInterval.random(in: 5...8)
            DispatchQueue.main.asyncAfter(deadline: .now() + rnd) {
                self.simulateTypingEvent(user: user)
            }
        }
    }
    
    func simulateReceivedMessage(user: User) {
        let message = Message(text: Lorem.words(1...8), user: user)
        messages.append(message)
        delegate?.messagesChanged(self, changes: [.added(message)])
    }
}

// Old school delegate
protocol ChannelReferenceDelegate: AnyObject {
        
    func channelDataUpdated(_ reference: ChannelReference, data: Channel, metadata: ChangeMatadata)
    
    func messagesChanged(_ reference: ChannelReference, changes: [Change<Message>])
    
    // With cool new options!
    @available(iOS 13, *)
    func messagesChanged(reference: ChannelReference, changes: NSDiffableDataSourceSnapshot<Never, Message>)
    
    
    func willStartFetchingRemoteData(_ reference: ChannelReference)
    func didStopFetchingRemoteData(_ reference: ChannelReference, success: Bool)
    
    func didReceiveChannelEvent(_ reference: ChannelReference, event: ChannelEvent, metadata: ChangeMatadata)
    func didReceiveTypingEvent(_ reference: ChannelReference, event: TypingEvent, metadata: ChangeMatadata)
    func didReceiveMemeberEvent(_ reference: ChannelReference, event: MemberEvent, metadata: ChangeMatadata)
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
        
        init(client: Client) {
            let ref = ChannelReference(client: client)
            ref.startUpdating() // TODO: listen for changes
            
            channel = ref.channel
            messages = ref.messages
            members = ref.members
            watchers = ref.watchers
        }
    }
}


extension ChannelReferenceDelegate {
    func channelDataUpdated(_ reference: ChannelReference, data: Channel, metadata: ChangeMatadata) {}
    
    @available(iOS 13, *)
    func messagesChanged(reference: ChannelReference, changes: NSDiffableDataSourceSnapshot<Never, Message>) { }
    func messagesChanged(_ reference: ChannelReference, changes: [Change<Message>]) { }

    func willStartFetchingRemoteData(_ reference: ChannelReference) { }
    func didStopFetchingRemoteData(_ reference: ChannelReference, success: Bool) { }
    
    func didReceiveChannelEvent(_ reference: ChannelReference, event: ChannelEvent, metadata: ChangeMatadata) {}
    func didReceiveTypingEvent(_ reference: ChannelReference, event: TypingEvent, metadata: ChangeMatadata) {}
    func didReceiveMemeberEvent(_ reference: ChannelReference, event: MemberEvent, metadata: ChangeMatadata) {}
}

enum Change<T> {
    case added(_ item: T)
    case updated(_ item: T)
    case moved(_ item: T)
    case removed(_ item: T)
}

struct ChangeMatadata {
    /// This change is done only locally and is not confirmed from the backend. You can use it for optimistic UI updates.
    var isPendingWrite: Bool = false
    
    /// Tha data comes from the local storage. Another update with the live data from the backend may came momentarily.
    var isFromLocalCache: Bool = false
}

// MARK: - DUMMY DATA ==================

private let john = User(name: "John")

private func initialMessages(currentUser: User) -> [Message] {
    [
        .init(text: "Hey!", user: currentUser),
        .init(text: "Hey there :)", user: john),
        .init(text: "How's it going today?", user: john),
        
        .init(text: "Hey!", user: currentUser),
        .init(text: "Hey there :)", user: john),
        .init(text: "How's it going today?", user: john),
        
        .init(text: "Hey!", user: currentUser),
        .init(text: "Hey there :)", user: john),
        .init(text: "How's it going today?", user: john),
    ]
}

