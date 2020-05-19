//
//  ChatListViewController.swift
//  AirChat
//
//  Created by Vojta on 19/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit

//class ChatListViewController: UICollectionViewController {
//
//    var channelListRef: ChannelListReference!
//
//    var channels: [ChannelListReference.ChannelThumbnailData] = []
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        setupUI()
//
//        channelListRef.delegate = self
//        channelListRef.currentSnapshot(includeLocalStorage: true) { [weak self] (result) in
//            switch result {
//            case let .success(snapshot):
////                self?.title = snapshot.channel.name
//                self?.reloadAllData(channels: snapshot.channels)
//
//                if snapshot.metadata.isFromLocalCache {
//                    // If the data come from the local storage, show the activity indicator
//                    let spinner = UIActivityIndicatorView()
//                    spinner.startAnimating()
//                    self?.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
//
//                } else {
//                    self?.navigationItem.rightBarButtonItem = nil
//                }
//
//            case let .failure(error):
//                self?.navigationItem.rightBarButtonItem = nil
//                print("Can't load the channel: \(error)")
//            }
//        }
//    }
//
//    func setupUI() {
//        self.collectionView.register(
//            UINib(nibName: "ChatThumbnailCell", bundle: nil),
//            forCellWithReuseIdentifier: ChatThumbnailCell.reuseIdentifier
//        )
//
//        self.collectionView.alwaysBounceVertical = true
//
//        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
//        flowLayout.itemSize = .init(width: view.bounds.width / 2.0 - 20,
//                                    height: view.bounds.height / 6.0 - 20)
//        flowLayout.minimumLineSpacing = 20
//        flowLayout.minimumInteritemSpacing = 20
//    }
//
//    func reloadAllData(channels: [ChannelListReference.ChannelThumbnailData]) {
//        self.channels = channels
//        collectionView.reloadData()
//    }
//
//
//
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return channels.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView
//            .dequeueReusableCell(withReuseIdentifier: ChatThumbnailCell.reuseIdentifier, for: indexPath) as! ChatThumbnailCell
//
//        let channelPreview = channels[indexPath.row]
//
//        cell.nameLabel.text = channelPreview.channel.name
//        cell.iconLabel.text = "😈"
//        cell.messagePreviewLabel.text = channelPreview.messages.last?.text ?? "..."
//
//        cell.backgroundColor = .tertiarySystemFill
//
//        return cell
//    }
//}
//
//extension ChatListViewController: ChannelListReferenceDelegate {
//    func channelsChanged(_ reference: ChannelListReference,
//                         changes: [Change<ChannelListReference.ChannelThumbnailData>],
//                         metadata: ChangeMatadata) {
//
//        collectionView.performBatchUpdates({
//            changes.forEach {
//                switch $0 {
//                case let .added(channel):
//                    channels.insert(channel, at: 0)
//                    collectionView.insertItems(at: [.init(row: 0, section: 0)])
//
//                case let .updated(channel):
//                    let idx = channels.firstIndex(where: { $0.channel.id == channel.channel.id })!
//                    channels[idx] = channel
//                    collectionView.reloadItems(at: [IndexPath(item: idx, section: 0)])
//
//                default: break
//                }
//            }
//        })
//
//    }
//}
