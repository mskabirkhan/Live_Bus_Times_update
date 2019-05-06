//
//  LocationSharedViewController.swift
//  Live Bus Time
//
//  Created by Kabir on 13/03/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class LocationSharedViewController: UIViewController {

    @IBOutlet weak var pickupMapView: RoundMapView!
    
    var pickupCoordinate: CLLocationCoordinate2D!
    var passengerKey: String!
    
    var regionRadius : CLLocationDistance = 2000
    var pin : MKPlacemark? = nil
    var locationPlacemark: MKPlacemark!

    var currentUserId = Auth.auth().currentUser?.uid
    //var id = Auth.auth().currentUser?.uid

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickupMapView.delegate = self
        locationPlacemark = MKPlacemark(coordinate: pickupCoordinate)
        dropPinFor(placemark: locationPlacemark)
        centerMapOnLocation(location: locationPlacemark.location!)
        DataService.instance.REF_TRIPS.child(passengerKey).observe(.value) { (tripSnapshot) in
            if tripSnapshot.exists() {
                //check for acceptance
                //below is in case someone else then this driver accepts the trip first
                if tripSnapshot.childSnapshot(forPath: "tripIsShared").value as? Bool == true {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                //if the customer cancels the trip before the driver can accept
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String) {
        self.pickupCoordinate = coordinate
        self.passengerKey = passengerKey
    }
    
    //location sharing button can be clicked upon request
    @IBAction func locationAcceptTripBtnPressed(_ sender: Any) {
        UpdateService.instance.acceptTrip(withPassengerKey: passengerKey, forDriverKey: currentUserId!)
        presentingViewController?.shouldPresentLoadingView(true)

    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)

    }
    
    
    /* 
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LocationSharedViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "pickupPoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil{
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }else {
            annotationView?.annotation = annotation
        }
        
        annotationView?.image = UIImage(named: "destinationAnnotation")
        return annotationView
    }
    
    func centerMapOnLocation(location : CLLocation) {
        //var userTrackingMode: MKUserTrackingMode {get set}
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        pickupMapView.setRegion(coordinateRegion, animated: true)
    }
    
   
    func dropPinFor(placemark : MKPlacemark) {
        pin = placemark
        
        for annotation in pickupMapView.annotations{
            pickupMapView.removeAnnotation(annotation)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        pickupMapView.addAnnotation(annotation)
    }
}
