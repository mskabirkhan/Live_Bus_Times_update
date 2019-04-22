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
    
    @IBOutlet weak var mapView: MKMapView!
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
        
        mapView.delegate = self
        
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
    
    
    
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
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
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
            
        }
    }
}
