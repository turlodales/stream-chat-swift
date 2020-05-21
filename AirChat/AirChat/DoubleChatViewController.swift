//
//  DoubleChatViewController.swift
//  AirChat
//
//  Created by Vojta on 21/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//

import UIKit

class DoubleChatViewController: UIViewController {
    
    @IBOutlet var mainStackView: UIStackView!
    
    var client: ChatClient!
    var channelId: Channel.Id!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let childControllers = 2
        
        for _ in 0..<childControllers {
            let vc = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(identifier: "ChatViewController") as! ChatViewController
            vc.channelRef = client.channelReference(id: channelId)
            
            vc.willMove(toParent: self)
            addChild(vc)
            vc.didMove(toParent: self)
            
            mainStackView.addArrangedSubview(vc.view)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        mainStackView.axis = UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown
            ? .vertical
            : .horizontal
    }
}
