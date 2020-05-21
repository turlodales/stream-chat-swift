//
//  UserCollectionCell.swift
//  AirChat
//
//  Created by Vojta on 21/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit

class UserCollectionCell: UICollectionViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .lightGray
    }
}
