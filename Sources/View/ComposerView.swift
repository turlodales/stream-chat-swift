//
//  ComposerView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

public final class ComposerView: UIView {
    
    public var style: ComposerViewStyle?
    
    /// A stack view for containers.
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [attachmentsCollectionView, buttonsStackView])
        stackView.axis = .vertical
        return stackView
    }()
    
    // MARK: - Text View Container
    
    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [filePickerButton, sendButton, activityIndicatorView])
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    
    /// An `UITextView`.
    /// You have to use the `text` property to change the value of the text view.
    public private(set) lazy var textView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.autocorrectionType = .no
        textView.delegate = self
        textView.backgroundColor = style?.backgroundColor
        
        if let style = style {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.1
            textView.attributedText = NSAttributedString(string: "",
                                                         attributes: [.foregroundColor: style.textColor,
                                                                      .font: style.font,
                                                                      .paragraphStyle: paragraphStyle])
        }
        
        return textView
    }()
    
    /// The default text view attributes.
    public var textViewTextAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.1
        return [.font: UIFont.systemFont(ofSize: 15), .paragraphStyle: paragraphStyle]
    }()
    
    /// A placeholder label.
    /// You have to use the `placeholderText` property to change the value of the placeholder label.
    public private(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = style?.tintColor
        textView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.equalTo(textView.textContainer.lineFragmentPadding)
            make.top.equalTo(textView.textContainerInset.top)
            make.right.equalToSuperview()
        }
        
        return label
    }()
    
    /// A send button.
    public private(set) lazy var sendButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage.Icons.send, for: .normal)
        button.snp.makeConstraints { $0.width.equalTo(CGFloat.composerButtonWidth).priority(999) }
        button.isHidden = true
        return button
    }()
    
    private lazy var filePickerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.Icons.image, for: .normal)
        button.snp.makeConstraints { $0.width.equalTo(CGFloat.composerButtonWidth).priority(999) }
        return button
    }()

    /// An `UIActivityIndicatorView`.
    public private(set) lazy var activityIndicatorView = UIActivityIndicatorView(style: .gray)
    
    /// The text of the text view.
    public var text: String {
        get { return
            textView.attributedText.string
        }
        set {
            textView.attributedText = NSAttributedString(string: newValue)
            updatePlaceholder()
        }
    }
    
    /// The placeholder text.
    public var placeholderText: String {
        get { return placeholderLabel.attributedText?.string ?? "" }
        set { placeholderLabel.attributedText = NSAttributedString(string: newValue, attributes: textViewTextAttributes) }
    }
    
    private weak var heightConstraint: Constraint?
    private weak var bottomConstraint: Constraint?
    private var baseTextHeight = CGFloat.greatestFiniteMagnitude
    
    /// Enables the detector of links in the text.
    public var linksDetectorEnabled = false
    var detectedURL: URL?
    
    private lazy var dataDetectorWorker: DataDetectorWorker? = linksDetectorEnabled
        ? (try? DataDetectorWorker(types: .link) { [weak self] _ in /*self?.updateOpenGraph($0)*/ })
        : nil
    
    // MARK: - Images Collection View
    
    /// Picked images.
    public var images: [UIImage] = []
    
    private lazy var attachmentsCollectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.itemSize = CGSize(width: .composerAttachmentWidth, height: .composerAttachmentHeight)
        collectionViewLayout.minimumLineSpacing = 1
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: .composerInnerPadding, bottom: 0, right: .composerInnerPadding)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.isHidden = true
        collectionView.backgroundColor = backgroundColor
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.register(cellType: AttachmentCollectionViewCell.self)
        collectionView.snp.makeConstraints { $0.height.equalTo(CGFloat.composerAttachmentsHeight) }
        
        return collectionView
    }()
    
    // MARK: -
    
    public func addToSuperview(_ view: UIView, placeholderText: String = "Write a message") {
        guard let style = style else {
            return
        }
        
        // Add to superview.
        view.addSubview(self)
        
        snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            heightConstraint = make.height.equalTo(CGFloat.composerHeight).constraint
            bottomConstraint = make.bottom.equalToSuperview().offset(-CGFloat.messageEdgePadding).constraint
        }
        
        // Apply style.
        backgroundColor = style.backgroundColor
        clipsToBounds = true
        layer.cornerRadius = style.cornerRadius
        layer.borderWidth = style.style(with: .normal).borderWidth
        layer.borderColor = style.style(with: .normal).borderColor.cgColor
        
        // Add buttons.
        addSubview(buttonsStackView)
        buttonsStackView.snp.makeConstraints { $0.top.right.bottom.equalToSuperview() }
        
        // Add text view.
        addSubview(textView)
        updateTextHeightIfNeeded()
        let textTopPadding: CGFloat = (CGFloat.composerHeight - baseTextHeight) / 2
        textView.contentInset = UIEdgeInsets(top: textTopPadding, left: 0, bottom: textTopPadding, right: 0)
        
        textView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.composerInnerPadding)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(buttonsStackView.snp.left)
        }
        
        // Add placeholder.
        self.placeholderText = placeholderText
        filePickerButton.tintColor = style.tintColor
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardUpdated(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardUpdated(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    /// Check if the content is valid: text is not empty or at least one image was added.
    public var isValidContent: Bool {
        return !textView.attributedText.string.isEmpty || !images.isEmpty
    }
    
    /// Reset states of all child views and clear all added/generated data.
    public func reset() {
        textView.attributedText = NSAttributedString(string: "")
        images = []
        attachmentsCollectionView.reloadData()
        attachmentsCollectionView.isHidden = true
        isEnabled = true
        activityIndicatorView.stopAnimating()
        updatePlaceholder()
        updateTextHeightIfNeeded()
    }
    
    /// Toggle `isUserInteractionEnabled` states for all child views.
    public var isEnabled: Bool = true {
        didSet {
            textView.resignFirstResponder()
            textView.isUserInteractionEnabled = isEnabled
            sendButton.isEnabled = isEnabled
            filePickerButton.isEnabled = isEnabled
            attachmentsCollectionView.isUserInteractionEnabled = isEnabled
            attachmentsCollectionView.alpha = isEnabled ? 1 : 0.5
        }
    }
    
    /// Update the placeholder and send button visibility.
    public func updatePlaceholder() {
        placeholderLabel.isHidden = textView.attributedText.length != 0
        DispatchQueue.main.async { self.updateSendButton() }
    }
    
    private func updateSendButton() {
        sendButton.isHidden = textView.attributedText.length == 0
    }
}

// MARK: - Text View Height

extension ComposerView {
    /// Update the height of the text view for a big text length.
    func updateTextHeightIfNeeded() {
        guard heightConstraint != nil  else {
            return
        }
        
        if baseTextHeight == .greatestFiniteMagnitude {
            let text = textView.attributedText
            textView.attributedText = NSAttributedString(string: "T", attributes: textViewTextAttributes)
            baseTextHeight = textViewContentSize.height.rounded()
            textView.attributedText = text
        }
        
        guard textView.attributedText.length > 0 else {
            updateTextHeight(baseTextHeight)
            return
        }
        
        updateTextHeight(textViewContentSize.height.rounded())
    }
    
    private var textViewContentSize: CGSize {
        return textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
    }
    
    private func updateTextHeight(_ height: CGFloat) {
        var height = min(max(height + (CGFloat.composerHeight - baseTextHeight), CGFloat.composerHeight),
                         CGFloat.composerMaxHeight)

        height += textView.isFirstResponder ? 0 : CGFloat.safeAreaBottom
        
        attachmentsCollectionView.isHidden = images.count == 0
        
        if !attachmentsCollectionView.isHidden {
            height += CGFloat.composerAttachmentsHeight
        }
        
        if let heightConstraint = heightConstraint, heightConstraint.layoutConstraints.first?.constant != height {
            heightConstraint.update(offset: height)
            layoutIfNeeded()
        }
    }
}

// MARK: - Text View Delegate

extension ComposerView: UITextViewDelegate {
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        updateTextHeightIfNeeded()
        updateSendButton()
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        updateTextHeightIfNeeded()
        updatePlaceholder()
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        updatePlaceholder()
        updateTextHeightIfNeeded()
        
        if !text.isEmpty {
            dataDetectorWorker?.match(text)
        }
    }
}

// MARK: - Keyboard Events

extension ComposerView {
    @objc func keyboardUpdated(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let value = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            superview != nil else {
                return
        }
        
        let willHide = notification.name == UIResponder.keyboardWillHideNotification
        let offset: CGFloat = willHide ? 0 : -value.cgRectValue.height
        bottomConstraint?.update(offset: offset - CGFloat.messageEdgePadding)
        
        layoutIfNeeded()
    }
}

// MARK: - Images Collection View

extension ComposerView: UICollectionViewDataSource {
    
    /// Enables the image picking with a given view controller.
    /// The view controller will be used to present `UIImagePickerController`.
//    public func enableImagePicking(with viewController: UIViewController) {
//        filePickerButton.isHidden = false
//
//        filePickerButton.addTap { [weak self, weak viewController] _ in
//            if let self = self, let viewController = viewController {
//                viewController.view.endEditing(true)
//                self.imagePickerButton.isEnabled = false
//
//                viewController.pickImage { info, authorizationStatus, removed in
//                    if let image = info[.originalImage] as? UIImage {
//                        self.images.insert(image, at: 0)
//                        self.imagesCollectionView.reloadData()
//                        self.updateTextHeightIfNeeded()
//                    } else if authorizationStatus != .authorized {
//                        print("❌ Photos authorization status: ", authorizationStatus)
//                    }
//
//                    if !self.textView.isFirstResponder {
//                        self.textView.becomeFirstResponder()
//                    }
//
//                    if authorizationStatus == .authorized || authorizationStatus == .notDetermined {
//                        self.imagePickerButton.isEnabled = true
//                    }
//                }
//            }
//        }
//    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as AttachmentCollectionViewCell
        cell.imageView.image = images[indexPath.item]
        
//        cell.removeButton.addTap { [weak self] _ in
//            if let self = self {
//                self.images.remove(at: indexPath.item)
//                self.imagesCollectionView.reloadData()
//                self.updateTextHeightIfNeeded()
//            }
//        }
        
        return cell
    }
}
