//
//  ChatThumbnailCell.swift
//  AirChat
//
//  Created by Vojta on 19/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit

class ChatThumbnailCell: UICollectionViewCell {

    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messagePreviewLabel: UILabel!
    
    static let reuseIdentifier = "\(String(describing: type(of: self)))"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        iconLabel.textColor = .white
        nameLabel.textColor = .white
        
        messagePreviewLabel.textColor = UIColor.white.withAlphaComponent(0.6)
    }
}

