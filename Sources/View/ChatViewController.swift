//
//  ChatViewController.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

public final class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var style = ChatViewStyle()
    
    public private(set) lazy var composerView: ComposerView = {
        let composerView = ComposerView(frame: .zero)
        composerView.style = style.composer
        return composerView
    }()
    
    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerMessageCell(style: style.incomingMessage)
        tableView.registerMessageCell(style: style.outgoingMessage)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGFloat.messagesBottomMargin, right: 0)
        view.insertSubview(tableView, at: 0)
        return tableView
    }()
    
    public var channelPresenter: ChannelPresenter?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupComposerView()
        setupTableView()
        channelPresenter?.load { [weak self] in self?.tableView.reloadData() }
    }
    
    func setupComposerView() {
        composerView.addToSuperview(view)
    }
    
    func setupTableView() {
        tableView.backgroundColor = style.backgroundColor
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelPresenter?.messages.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let presenter = channelPresenter,
            indexPath.row < presenter.messages.count else {
                return .unused
        }
        
        let message = presenter.messages[indexPath.row]
        
        let isIncoming = message.user.id.hashValue % 2 == 0
        
        let cell = tableView.dequeueMessageCell(for: indexPath,
                                                style: isIncoming ? style.incomingMessage : style.outgoingMessage)
        cell.update(message: message.text)
        
        var showAvatar = true
        
        if indexPath.row < (presenter.messages.count - 1) {
            let nextMessage = presenter.messages[indexPath.row + 1]
            showAvatar = nextMessage.user != message.user
            
            if !showAvatar {
                cell.paddingType = .small
            }
        }
        
        if indexPath.row > 0, presenter.messages[indexPath.row - 1].user == message.user {
            cell.update(isContinueMessage: true)
        }
        
        if !message.attachments.isEmpty {
            cell.add(attachments: message.attachments, userName: message.user.name)
        }
        
        if showAvatar {
            cell.update(name: message.user.name, date: message.created)
            cell.update(avatarURL: message.user.avatarURL, name: message.user.name)
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MessageTableViewCell {
            cell.free()
        }
    }
}
