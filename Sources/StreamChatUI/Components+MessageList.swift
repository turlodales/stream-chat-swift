//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit.UIImage

public extension _Components {
    struct MessageListUI {
        public var collectionView: ChatMessageListCollectionView<ExtraData>.Type = ChatMessageListCollectionView<ExtraData>.self
        public var collectionLayout: ChatMessageListCollectionViewLayout.Type = ChatMessageListCollectionViewLayout.self
        public var channelNamer: ChatChannelNamer<ExtraData> = DefaultChatChannelNamer()
        public var scrollOverlayView: ChatMessageListScrollOverlayView.Type = ChatMessageListScrollOverlayView.self
        public var messageContentSubviews = MessageContentViewSubviews()
        public var messageReactions = MessageReactions()
    }

    struct MessageReactions {
        public var reactionsBubbleView: _ChatMessageReactionsBubbleView<ExtraData>.Type =
            _ChatMessageDefaultReactionsBubbleView<ExtraData>.self
        public var reactionsView: _ChatMessageReactionsView<ExtraData>.Type = _ChatMessageReactionsView<ExtraData>.self
        public var reactionItemView: _ChatMessageReactionsView<ExtraData>.ItemView.Type =
            _ChatMessageReactionsView<ExtraData>.ItemView.self
    }

    struct MessageContentViewSubviews {
        public var authorAvatarView: ChatAvatarView.Type = ChatAvatarView.self
        public var attachmentSubviews = MessageAttachmentViewSubviews()
        public var threadParticipantAvatarView: ChatAvatarView.Type = ChatAvatarView.self
        public var errorIndicator: ChatMessageErrorIndicator.Type = ChatMessageErrorIndicator.self
        public var linkPreviewView: _ChatMessageLinkPreviewView<ExtraData>.Type = _ChatMessageLinkPreviewView<ExtraData>.self
    }

    struct MessageAttachmentViewSubviews {
        public var loadingIndicator: ChatLoadingIndicator.Type = ChatLoadingIndicator.self
        // Files
        public var fileAttachmentListView: _ChatMessageFileAttachmentListView<ExtraData>
            .Type = _ChatMessageFileAttachmentListView<ExtraData>.self
        public var fileAttachmentItemView: _ChatMessageFileAttachmentListView<ExtraData>.ItemView.Type =
            _ChatMessageFileAttachmentListView<ExtraData>.ItemView.self
        // Images
        public var imageGallery: _ChatMessageImageGallery<ExtraData>.Type = _ChatMessageImageGallery<ExtraData>.self
        public var imageGalleryItem: _ChatMessageImageGallery<ExtraData>.ImagePreview.Type =
            _ChatMessageImageGallery<ExtraData>.ImagePreview.self
        public var imageGalleryItemUploadingOverlay: _ChatMessageImageGallery<ExtraData>.UploadingOverlay.Type =
            _ChatMessageImageGallery<ExtraData>.UploadingOverlay.self
        // Interactive attachments
        public var interactiveAttachmentView: _ChatMessageInteractiveAttachmentView<ExtraData>.Type =
            _ChatMessageInteractiveAttachmentView<ExtraData>.self
        public var interactiveAttachmentActionButton: _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.Type =
            _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.self
        // Giphy
        public var giphyAttachmentView: _ChatMessageGiphyView<ExtraData>.Type =
            _ChatMessageGiphyView<ExtraData>.self
        public var giphyBadgeView: _ChatMessageGiphyView<ExtraData>.GiphyBadge.Type = _ChatMessageGiphyView<ExtraData>.GiphyBadge
            .self
    }
}
