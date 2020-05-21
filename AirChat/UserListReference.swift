//
//  UserListReference.swift
//  AirChat
//
//  Created by Vojta on 20/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit
import CoreData
import Combine

extension ChatClient {
    func userListReference(query: UserListReference.Query) -> UserListReference {
        .init(query: query, client: self)
    }
}

/// An object representing a list of channel. You can use it to create a list of channels based on the provided query and
/// and observe the changes in the list.
///
/// - Note: It's completely safe to have multiple references to the same list if your scenario requires it.
///
class UserListReference: Reference {
    
    // MARK:  -------------------- -------------------- Public -------------------- --------------------
    
    struct Query {
        let filter: Filter<User>
    }

    var query: Query
    
    private(set) lazy var users: [User] = { fatalError("Call `startUpdating` first") }()
    
    weak var delegate: UserListReferenceDelegate?
    
    /// Synchronously loads the data for the referenced object form the local cache and starts observing its changes.
    ///
    /// It also anynchronously fetches the data from the servers. If the remote data differs from the locally cached one,
    /// `ChannelReference` uses the `delegate` methods to inform about the changes.
    func startUpdating() {
        
        fetchResultsController.delegate = self
        try! fetchResultsController.performFetch()
        
        users = fetchResultsController.fetchedObjects!.map(User.init)
        
        generateNewSnapshot()
        delegate?.usersChanged(self, changes: currentSnapshot)
        
        delegate?.willStartFetchingRemoteData(self)
                
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.delegate?.didStopFetchingRemoteData(self, success: true)
        }
    }
    
    func addUser() {
        let user = User(name: Lorem.firstName)
        client.write {
            user.save(to: $0)
        }
    }
    
    func updateQuery(query: Query) throws { fatalError() }

    init(query: Query, client: ChatClient) {
        self.query = query
        super.init(client: client)
    }
        
    // MARK:  -------------------- -------------------- Private -------------------- --------------------
    
    private lazy var fetchResultsController: NSFetchedResultsController<UserDTO> = {
        let request = User.usersFetchRequest(query: self.query)
        return .init(fetchRequest: request,
                     managedObjectContext: self.client.persistentContainer.viewContext,
                     sectionNameKeyPath: nil,
                     cacheName: nil)
    }()
    
    
    // The code below is crazy 😅 , courtesy https://alexj.org/01/nsfetchedresultscontroller-diffable-datasource/
    
    // NSDiffableDataSourceSnapshot is a new API, it's not documented, it's madness!
    
    var currentSnapshot = NSDiffableDataSourceSnapshot<Int, User>()
    
    private func generateNewSnapshot() {
        var initialSnapshot = NSDiffableDataSourceSnapshot<Int, User>()
        initialSnapshot.appendSections([0])

        if let objects = fetchResultsController.fetchedObjects?.map(User.init) {
            initialSnapshot.appendItems(objects, toSection: 0)
        }

        self.currentSnapshot = initialSnapshot
    }
    
    private var transientChanges: [CollectionDifference<User>.Change] = []
    private var updatedObjects: Set<User> = []

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        transientChanges.removeAll()
        updatedObjects.removeAll()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        let object = User(from: anObject as! UserDTO)

        switch type {
        case .insert:
            let insertionIndex = newIndexPath!
            transientChanges.append(.insert(offset: insertionIndex.row, element: object, associatedWith: nil))

        case .update:
            updatedObjects.insert(object)

        case .move:
            let sourceIndex = indexPath!.row
            let destinationIndex = newIndexPath!.row

            updatedObjects.insert(object)
            transientChanges.append(.insert(offset: destinationIndex, element: object, associatedWith: sourceIndex))
            transientChanges.append(.remove(offset: sourceIndex, element: object, associatedWith: destinationIndex))

        case .delete:
            let deletedIndex = indexPath!.row
            transientChanges.append(.remove(offset: deletedIndex, element: object, associatedWith: nil))

        @unknown default:
            fatalError("Unhandled \(NSFetchedResultsChangeType.self) \(type)")
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let collectionDifference = CollectionDifference(transientChanges) else {
            // In theory, NSFetchedResultsController should deliver valid changes. In practice, I don't trust it so fall
            // back to generating a new snapshot if the changes can't be used as a diff.
            assertionFailure("Unable to create a collection difference from the changes \(transientChanges)")
            generateNewSnapshot()
            return
        }

        var newSnapshot = self.currentSnapshot
        for change in collectionDifference {
            switch change {
            case .insert(0, let object, _) where newSnapshot.numberOfItems(inSection: 0) == 0:
                newSnapshot.appendItems([object], toSection: 0)

            case .insert(0, let object, _):
                newSnapshot.insertItems([object], beforeItem: newSnapshot.itemIdentifiers(inSection: 0).first!)

            case .insert(newSnapshot.itemIdentifiers(inSection: 0).count, let object, _):
                newSnapshot.appendItems([object], toSection: 0)

            case .insert(let index, let object, _):
                let existingItem = newSnapshot.itemIdentifiers(inSection: 0)[index]
                newSnapshot.insertItems([object], beforeItem: existingItem)

            case .remove(_, let object, _):
                newSnapshot.deleteItems([object])
            }
        }

        newSnapshot.reloadItems(Array(updatedObjects))
        assert(newSnapshot.itemIdentifiers == fetchResultsController.fetchedObjects?.map(User.init) ?? [],
               "Final snapshots items do not match the FRC's fetched objects")

        self.currentSnapshot = newSnapshot
        
        delegate?.usersChanged(self, changes: newSnapshot)
    }
}

extension UserListReference: NSFetchedResultsControllerDelegate {
    
    // TODO ...
    
   
}

protocol UserListReferenceDelegate: AnyObject {
    func willStartFetchingRemoteData(_ reference:  UserListReference)
    func didStopFetchingRemoteData(_ reference:  UserListReference, success: Bool)
    
    func usersChanged(_ reference: UserListReference, changes: NSDiffableDataSourceSnapshot<Int, User>)
}

extension UserListReferenceDelegate {
    func willStartFetchingRemoteData(_ reference:  UserListReference) {}
    func didStopFetchingRemoteData(_ reference:  UserListReference, success: Bool) {}
    func usersChanged(_ reference: UserListReference, changes: NSDiffableDataSourceSnapshot<Int, User>) {}
}

// Combine wrapper example

@available(iOS 13, *)
extension UserListReference {
    final class ListChangesPublisher: Publisher {
        typealias Output = NSDiffableDataSourceSnapshot<Int, User>
        typealias Failure = Never
        
        private let reference: UserListReference
        
        init(reference: UserListReference) {
            self.reference = reference
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = ListChangesSubscription(subscriber: subscriber, reference: reference)
            subscriber.receive(subscription: subscription)
        }
    }
    
    final class ListChangesSubscription<S: Subscriber>: Subscription
        where S.Input == NSDiffableDataSourceSnapshot<Int, User>
    {
        private var subscriber: S?
        private let reference: UserListReference
        
        init(subscriber: S, reference: UserListReference) {
            self.subscriber = subscriber
            self.reference = reference
            reference.delegate = self
            reference.startUpdating()
        }
        
        func request(_ demand: Subscribers.Demand) {
        }
        
        func cancel() {
            subscriber = nil
        }
    }
}

extension UserListReference.ListChangesSubscription: UserListReferenceDelegate {
    func usersChanged(_ reference: UserListReference, changes: NSDiffableDataSourceSnapshot<Int, User>) {
        _ = subscriber?.receive(changes)
    }
}
