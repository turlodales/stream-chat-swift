//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Observers the storage for messages pending send and sends them.
class MessageSender<ExtraData: ExtraDataTypes>: Worker {
    lazy var observer = ListDatabaseObserver<MessageDTO, MessageDTO>(context: self.database.backgroundReadOnlyContext,
                                                                     fetchRequest: MessageDTO.messagesPendingSendFetchRequest(),
                                                                     itemCreator: { $0 })
    
    override init(database: DatabaseContainer, webSocketClient: WebSocketClient, apiClient: APIClient) {
        super.init(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
        
        DispatchQueue.global().async {
            self.observer.onChange = { [unowned self] in self.handleChanges(changes: $0) }
            do {
                try self.observer.startObserving()
                // Handle existing unread messages. We can ignore the index path completely
                let changes = self.observer.items.map { ListChange.insert($0, index: .init(row: 0, section: 0)) }
                self.handleChanges(changes: changes)
            } catch {
                log.error("Error starting MessageSender observer: \(error)")
            }
        }
    }
    
    func handleChanges(changes: [ListChange<MessageDTO>]) {
        changes.forEach { change in
            switch change {
            case .insert(let dto, index: _):
                let authorDTO = dto.user
                let userPayload = UserPayload<ExtraData.User>(id: authorDTO.id,
                                                              role: UserRole(rawValue: authorDTO.userRoleRaw) ?? .user,
                                                              createdAt: authorDTO.userCreatedAt,
                                                              updatedAt: authorDTO.userUpdatedAt,
                                                              lastActiveAt: nil,
                                                              isOnline: false,
                                                              isInvisible: false,
                                                              isBanned: authorDTO.isBanned,
                                                              extraData: try! JSONDecoder.stream.decode(ExtraData.User.self,
                                                                                                        from: authorDTO.extraData))
                
                let payload: MessagePayload<ExtraData> = .init(id: dto.id,
                                                               type: MessageType(rawValue: dto.type)!,
                                                               user: userPayload,
                                                               createdAt: dto.createdAt,
                                                               updatedAt: dto.updatedAt,
                                                               deletedAt: dto.deletedAt,
                                                               text: dto.text,
                                                               command: dto.command,
                                                               args: dto.args,
                                                               parentId: dto.parentId,
                                                               showReplyInChannel: dto.showReplyInChannel,
                                                               mentionedUsers: [],
                                                               replyCount: Int(dto.replyCount),
                                                               extraData: NoExtraData() as! ExtraData.Message,
                                                               reactionScores: dto.reactionScores,
                                                               isSilent: dto.isSilent)
                
                let endpoint: Endpoint<EmptyResponse> = .sendMessage(messagePayload: payload,
                                                                     cid: try! ChannelId(cid: dto.channel.cid))
                
                let messageId = dto.id
                sendMessage(messageId: messageId, endpoint: endpoint)
                
            case .move, .update, .remove:
                break
            }
        }
    }
    
    func sendMessage(messageId: MessageId, endpoint: Endpoint<EmptyResponse>) {
        apiClient.request(endpoint: endpoint) { (result) in
            switch result {
            case .success:
                self.database.write { (session) in
                    let message = session.loadMessageDTO(id: messageId)
                    if message?.additionalState == .pendingSend {
                        message?.additionalState = nil
                    }
                }
                
            case let .failure(error):
                log.error("Sending the message failed: \(error)")
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    self.sendMessage(messageId: messageId, endpoint: endpoint)
                }
            }
        }
    }
}
