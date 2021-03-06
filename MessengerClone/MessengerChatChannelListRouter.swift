//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class MessengerChatChannelListRouter: ChatChannelListRouter {
    override func openChat(for channel: _ChatChannel<NoExtraData>) {
        let vc = MessengerChatChannelViewController()
        vc.channelController = rootViewController.controller.client.channelController(for: channel.cid)
        
        guard let navController = navigationController else {
            log.error("Can't push chat detail, no navigation controller available")
            return
        }
        
        navController.show(vc, sender: self)
    }
    
    override func openCreateNewChannel() {}
}
