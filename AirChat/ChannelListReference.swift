//
//  ChannelListReference.swift
//  AirChat
//
//  Created by Vojta on 20/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import Foundation
import CoreData
import Combine

extension ChatClient {
    func channelListReference(query: ChannelListReference.Query) -> ChannelListReference {
        .init(query: query, client: self)
    }
}

/// An object representing a list of channel. You can use it to create a list of channels based on the provided query and
/// and observe the changes in the list.
///
/// - Note: It's completely safe to have multiple references to the same list if your scenario requires it.
///
class ChannelListReference: Reference {
    
    // MARK:  -------------------- -------------------- Public -------------------- --------------------
    
    struct Query {
        let filter: Filter<Channel>
    }

    private(set) var query: Query
    
    private(set) lazy var channels: [Channel] = { fatalError("Call `startUpdating` first") }()
    
    weak var delegate: ChannelListReferenceDelegate?
    
    /// Creates a new channel
    func createNewChannel(otherUser: User) {
        client.write { context in
            var channel = Channel(name: "Chat with \(otherUser.name)")
            channel.members = [self.currentUser, otherUser]
            channel.save(to: context)
        }
    }
    
    /// Synchronously loads the data for the referenced object form the local cache and starts observing its changes.
    ///
    /// It also anynchronously fetches the data from the servers. If the remote data differs from the locally cached one,
    /// `ChannelReference` uses the `delegate` methods to inform about the changes.
    func startUpdating() {
        
        fetchResultsController.delegate = self
        try! fetchResultsController.performFetch()
        
        channels = fetchResultsController.fetchedObjects!.map(Channel.init)

        delegate?.willStartFetchingRemoteData(self)
                
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.delegate?.didStopFetchingRemoteData(self, success: true)
        }
    }
    
    func updateQuery(query: Query) -> Cancellable { fatalError() }

    init(query: Query, client: ChatClient) {
        self.query = query
        super.init(client: client)
    }
        
    // MARK:  -------------------- -------------------- Private -------------------- --------------------
    
    
    private lazy var fetchResultsController: NSFetchedResultsController<ChannelDTO> = {
        let request = Channel.channelsFetchRequest(query: self.query)
        return .init(fetchRequest: request,
                     managedObjectContext: self.client.persistentContainer.viewContext,
                     sectionNameKeyPath: nil,
                     cacheName: nil)
    }()
}

extension ChannelListReference: NSFetchedResultsControllerDelegate {
    
    // TODO ...
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        channels = fetchResultsController.fetchedObjects!.map(Channel.init)
        delegate?.channelsChanged(self, changes: [])
    }
}

protocol ChannelListReferenceDelegate: AnyObject {
    func willStartFetchingRemoteData(_ reference: ChannelListReference)
    func didStopFetchingRemoteData(_ reference: ChannelListReference, success: Bool)
    
    func channelsChanged(_ reference: ChannelListReference, changes: [Change<Channel>])
}

extension ChannelListReferenceDelegate {
    func willStartFetchingRemoteData(_ reference: ChannelListReference) { }
    func didStopFetchingRemoteData(_ reference: ChannelListReference, success: Bool) { }
    
    func channelsChanged(_ reference: ChannelListReference, changes: [Change<Channel>]) { }
}

@available(iOS 13, *)
extension ChannelListReference {
    class Observable: ObservableObject, ChannelListReferenceDelegate {
        
        @Published var isFetchingRemotely: Bool = false
        @Published var channels: [Channel] = []
        
        private let reference: ChannelListReference
        
        func createNewChannel(otherUser: User) {
            reference.createNewChannel(otherUser: otherUser)
        }
        
        init(reference: ChannelListReference) {
            self.reference = reference
            reference.delegate = self
            reference.startUpdating()
            channels = reference.channels
        }
        
        convenience init(query: Query, client: ChatClient) {
            self.init(reference: ChannelListReference(query: query, client: client))
        }
        
        func channelsChanged(_ reference: ChannelListReference, changes: [Change<Channel>]) {
            // We don't care about the atomic updates, we just need to update everything and SwiftUI will figure it out
            self.channels = reference.channels
        }
        
        func willStartFetchingRemoteData(_ reference: ChannelListReference) {
            isFetchingRemotely = true
        }
        
        func didStopFetchingRemoteData(_ reference: ChannelListReference, success: Bool) {
            isFetchingRemotely = false
        }
    }
}

