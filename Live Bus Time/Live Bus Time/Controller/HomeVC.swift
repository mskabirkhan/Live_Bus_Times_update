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
    
    @IBOutlet weak var map: MKMapView!     //Map
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    
    var delegate: CenterVCDelegate?
    
    var manager: CLLocationManager?
    
    var regionRadius: CLLocationDistance = 1000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthStatus()
        
        map.delegate = self
        
        centerMapOnUserLocation()
        
    }
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            manager?.startUpdatingLocation()
        }else{
            manager?.requestAlwaysAuthorization()
            manager?.requestWhenInUseAuthorization()
            
        }
    }
    
    
    //ceneter map view on location
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegion(center: map.userLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        map.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func actionBtnWasPressed(_ sender: Any) {
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
    
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        centerMapOnUserLocation()
    }
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
    
}


extension HomeVC: CLLocationManagerDelegate {
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

            if status == .authorizedAlways{
                map.showsUserLocation = true
                map.userTrackingMode = .follow
                
            }
        }
    }
