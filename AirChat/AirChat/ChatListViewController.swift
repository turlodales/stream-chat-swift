//
//  ChatListViewController.swift
//  AirChat
//
//  Created by Vojta on 19/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import SwiftUI

class ChatListViewController: UIHostingController<ChatListView> {
    
    init(reference: ChannelListReference,
         didSelectChatId: @escaping (Channel.Id) -> Void,
         didPressUserListButton: @escaping () -> Void) {
        let view = ChatListView(reference: .init(reference: reference),
                                didSelectChat: didSelectChatId,
                                didPressUserListButton: didPressUserListButton)
        super.init(rootView: view)
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


struct ChatListView: View {
    
    @ObservedObject var reference: ChannelListReference.Observable

    var didSelectChat: ((_ chatID: String) -> Void)?
    var didPressUserListButton: (() -> Void)?
        
    var body: some View {
        
        List(reference.channels.reversed()) { channel in
            VStack {
                Button(action: { self.didSelectChat?(channel.id) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(channel.name)
                            Text(channel.lastMessage?.text ?? "no messages")
                                .opacity(0.6)
                        }.foregroundColor(.black)

                        Spacer()
                    }
                    .padding(20)
                    .background(Color.gray)
                }
            }.frame(height: 80)
        }
        .navigationBarTitle(reference.isFetchingRemotely ? "loading ..." : "Chats")
        .navigationBarItems(
            leading: Button(action: {
                    self.reference.createNewChannel(otherUser: .init(name: Lorem.firstName))
                }, label: { Text("+") }
            ),
            trailing: Button(action: {
                self.didPressUserListButton?()
                }, label: { Text("Users") } )
        )
        .animation(.default)
    }
}
