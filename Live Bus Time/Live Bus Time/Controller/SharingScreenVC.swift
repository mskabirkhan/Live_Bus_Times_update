//
//  SharingScreenVC.swift
//  Live Bus Time
//
//  Created by Kabir on 24/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit
import MapKit


class SharingScreenVC: UIViewController {

    @IBOutlet weak var pickupMapView: MKMapView!
    var regionRadius : CLLocationDistance = 1500
    var pin : MKPlacemark? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)

    }
    
    
    @IBAction func locationSharedBtnWasPressed(_ sender: Any) {
    }
    
}

extension SharingScreenVC : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "busStand"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil
        {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        else
        {
            annotationView?.annotation = annotation
        }
        
        annotationView?.image = UIImage(named: "destinationAnnotation")
        
        return annotationView
}
    
    func centerMapOnLocation(location : CLLocation) {
        
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        pickupMapView.setRegion(coordinateRegion, animated: true)
    }
    
    func dropPinFor(placemark : MKPlacemark) {
        
        pin = placemark
        
        for annotation in pickupMapView.annotations
        {
            pickupMapView.removeAnnotation(annotation)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        
        pickupMapView.addAnnotation(annotation)
    }
}
