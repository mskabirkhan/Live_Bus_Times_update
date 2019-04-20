//
//  HomeVC.swift
//  Live Bus Time
//
//  Created by Kabir on 23/01/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class HomeVC: UIViewController, MKMapViewDelegate {
    
    //Map
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    
    var delegate: CenterVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
    }
    
    @IBAction func actionBtnWasPressed(_ sender: Any) {
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
    
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
}
