//
//  ViewController.swift
//  Live Bus Time
//
//  Created by Kabir on 23/01/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    //Map
    @IBOutlet weak var map: MKMapView!
    
    // to get search bar at th top
    @IBAction func search(_ sender: Any) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self as? UISearchBarDelegate
        present(searchController, animated: true, completion: nil)
    }
    
        //to get search bar working
    func searchBarSearchButtonClicked(_searchBar: UISearchBar){
        //Ignoring Users
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        //Activity Indicator
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        self.view.addSubview(activityIndicator)
        
        //Hide search bar
        _searchBar.resignFirstResponder
        dismiss(animated: true, completion: nil)
        
        //Create search bar request
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = _searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start{ (response, Error) in
            if response == nil{
                print("ERROR")
            }
            else
            {
                //Remove Annotations
                let annotations = self.map.annotations
                self.map.removeAnnotations(annotations)
                
                //Gettinng DATA
                let  latitude = response?.boundingRegion.center.latitude
                let  longitude = response?.boundingRegion.center.longitude
                
                //create annotations
                let annotation = MKPointAnnotation()
                annotation.title = _searchBar.text
                //annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.map.addAnnotation(annotation)
                
                
            }
            
        }
        
    }
    
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
    }
    
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            map.setRegion(region, animated: true)
        }
    }
    
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
        }
    }
    
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            map.showsUserLocation = true
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
            break
        case .denied:
            // Show alert instructing them how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // Show an alert letting them know what's up
            break
        case .authorizedAlways:
            break
        }
    }
}


extension ViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      guard let location = locations.last else { return }
       let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
       map.setRegion(region, animated: true)
    
}

    
   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       checkLocationAuthorization()
   }
}
