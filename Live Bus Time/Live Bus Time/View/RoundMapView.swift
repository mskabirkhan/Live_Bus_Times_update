//
//  RoundMapView.swift
//  Live Bus Time
//
//  Created by Kabir on 25/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit
import MapKit

class RoundMapView: MKMapView {

    
    
    
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        
        self.layer.cornerRadius = self.frame.width / 2 //to create a perfect circle
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 10.0
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
