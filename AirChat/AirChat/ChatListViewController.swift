//
//  ChatListViewController.swift
//  AirChat
//
//  Created by Vojta on 19/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import SwiftUI

class ChatListViewController: UIHostingController<ChatListView> {
    
    init(reference: ChannelListReference, didSelectChatId: @escaping (Channel.Id) -> Void) {
        let view = ChatListView(reference: .init(reference: reference), didSelectChat: didSelectChatId)
        super.init(rootView: view)
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


struct ChatListView: View {
    
    @ObservedObject var reference: ChannelListReference.Observable

    var didSelectChat: ((_ chatID: String) -> Void)?
        
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            ForEach(reference.channels.reversed()) { thumb in
                
                Button(action: { self.didSelectChat?(thumb.channel.id) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(thumb.channel.name)
                            Text(thumb.recentMessages.last?.text ?? "no messages")
                                .opacity(0.6)
                        }.foregroundColor(.black)

                        Spacer()
                    }
                    .padding(20)
                    .background(Color.gray)
                    
                }.frame(height: 80)
            }
            
            Spacer()
            
        }
        .navigationBarTitle(reference.isFetchingRemotely ? "loading ..." : "Chats")
        .animation(.default)
    }
}
