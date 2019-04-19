//
//  RoundImageView.swift
//  Live Bus Time
//
//  Created by Kabir on 19/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit

class RoundImageView: UIImageView {

    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
    }

}
