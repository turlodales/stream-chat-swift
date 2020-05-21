//
//  UsersCollectionViewController.swift
//  AirChat
//
//  Created by Vojta on 21/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit
import Combine

// Inspired by https://thoughtbot.com/blog/combine-diffable-data-source

private let reuseIdentifier = "Cell"

class UsersCollectionViewController: UICollectionViewController {

    var reference: UserListReference!
    var updateSubscription: AnyCancellable?
    
    lazy var dataSource: UICollectionViewDiffableDataSource<Int, User> = {
        .init(collectionView: self.collectionView) { (collectionView, indexPath, user) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! UserCollectionCell
            cell.nameLabel.text = user.name
            return cell
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupReference()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add User",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(addUser))
    }
    
    @objc func addUser() {
        reference.addUser()
    }
    
    func setupUI() {
        // Register cell classes
        self.collectionView!.register(
            UINib(nibName: "UserCollectionCell", bundle: nil),
            forCellWithReuseIdentifier: reuseIdentifier
        )
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = .init(width: view.bounds.width / 2.0 - 20, height: 100)
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 10
        
        collectionView.backgroundColor = .white
    }
    
    func setupReference() {
        // Subscribe for updates
        updateSubscription = UserListReference.ListChangesPublisher(reference: reference)
            .sink { self.dataSource.apply($0) }
    }
}
