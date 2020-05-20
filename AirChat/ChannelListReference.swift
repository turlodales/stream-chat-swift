//
//  ChannelListReference.swift
//  AirChat
//
//  Created by Vojta on 20/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import Foundation

extension Client {
    func channelListReference(query: ChannelListReference.Query) -> ChannelListReference {
        .init(query: query, client: self)
    }
}

struct ChannelThumbnailData: Hashable {
    let channel: Channel
    let recentMessages: [Message]
}

extension ChannelThumbnailData: Identifiable {
    var id: Channel.Id { channel.id }
}

class ChannelListReference: Reference {
    
    struct Query {
        let filter: Filter
    }
    
    private(set) lazy var channels: [ChannelThumbnailData] = { fatalError("Call `startUpdating` first") }()
    
    weak var delegate: ChannelListReferenceDelegate?
    
    init(query: Query, client: Client) {
        super.init(client: client)
    }
    
    /// Synchronously loads the data for the referenced object form the local cache and starts observing its changes.
    ///
    /// It also anynchronously fetches the data from the servers. If the remote data differs from the locally cached one,
    /// `ChannelReference` uses the `delegate` methods to inform about the changes.
    func startUpdating() {
        channels = initialChannels(currentUser: client.currentUser)
        
        delegate?.willStartFetchingRemoteData(self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.simulateNewChannel()
        }
    }
    
    func simulateNewChannel() {
        self.delegate?.didStopFetchingRemoteData(self, success: true)
        
        let channel = ChannelThumbnailData(
            channel: .init(name: "Tommaso"),
            recentMessages: [
                .init(text: "Are you done with the v3 version yet??? It's extremely important we realease this ASAP!", user: User(name: "Tommaso")),
            ]
        )
        self.channels.append(channel)
        self.delegate?.channelsChanged(self, changes: [.added(channel)])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let channel = ChannelThumbnailData(
                channel: .init(name: "Tommaso"),
                recentMessages: [
                    .init(text: "Are you done with the v3 version yet??? It's extremely important we realease this ASAP!", user: User(name: "Tommaso")),
                    .init(text: "Seriously guys ... 👍", user: User(name: "Tommaso")),

                ]
            )
            self.channels[self.channels.count - 1] = channel
            self.delegate?.channelsChanged(self, changes: [.updated(channel)])
        }
    }
    
    func updateQuery(query: Query) -> Cancellable { fatalError() }
}

protocol ChannelListReferenceDelegate: AnyObject {
    func willStartFetchingRemoteData(_ reference: ChannelListReference)
    func didStopFetchingRemoteData(_ reference: ChannelListReference, success: Bool)
    
    func channelsChanged(_ reference: ChannelListReference, changes: [Change<ChannelThumbnailData>])
}

extension ChannelListReferenceDelegate {
    func willStartFetchingRemoteData(_ reference: ChannelListReference) { }
    func didStopFetchingRemoteData(_ reference: ChannelListReference, success: Bool) { }
    
    func channelsChanged(_ reference: ChannelListReference, changes: [Change<ChannelThumbnailData>]) { }
}


import Combine
@available(iOS 13, *)
extension ChannelListReference {
    class Observable: ObservableObject, ChannelListReferenceDelegate {

        @Published var isFetchingRemotely: Bool = false
        @Published var channels: [ChannelThumbnailData] = []
        
        private let reference: ChannelListReference

        init(reference: ChannelListReference) {
            self.reference = reference
            reference.delegate = self
            reference.startUpdating()
            channels = reference.channels
        }

        convenience init(query: Query, client: Client) {
            self.init(reference: ChannelListReference(query: query, client: client))
        }
        
        func channelsChanged(_ reference: ChannelListReference, changes: [Change<ChannelThumbnailData>]) {
            // We don't case about the atomic updates, we just need to update everything and SwiftUI will figure it out
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





// Dummy data


private func initialChannels(currentUser: User) -> [ChannelThumbnailData] {
    [
        .init(channel: .init(name: "Bahadir"), recentMessages: [.init(text: "Hey there", user: currentUser)]),
        .init(channel: .init(name: "Alex"), recentMessages: [.init(text:  "Are you sure you want to use `!` ?", user: User(name: "Alex"))]),
    ]
}

