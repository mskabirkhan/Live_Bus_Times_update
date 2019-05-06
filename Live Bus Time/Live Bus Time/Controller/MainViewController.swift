//
//  MainViewController.swift
//  Live Bus Time
//
//  Created by Kabir on 23/01/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase

//
class MainViewController: UIViewController, Alertable  {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    @IBOutlet weak var centerMapBtn: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: CircleView!
    @IBOutlet weak var cancelBtn: UIButton!
    
    
    var delegate: CenterVCDelegate?
    var ref: DatabaseReference!
    var manager: CLLocationManager?
    var regionRadius: CLLocationDistance = 1000
    var currentUserId : String?             //look at into the

    
    var tableView = UITableView()
    var matchingItems : [MKMapItem] = [MKMapItem]()
    var selectedItemPlacemark : MKPlacemark? = nil
    var route : MKRoute!
    //let locationManager = CLLocationManager() // declared var to get user location SF

    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
//        // Ask for Authorisation from the User. SF
//        self.locationManager.requestAlwaysAuthorization()
//        
//        // For use in foreground
//        self.locationManager.requestWhenInUseAuthorization()
//        
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager.delegate = self
//            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
//            locationManager.startUpdatingLocation()
//        } // SF
        
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationAuthStatus()

       //guard Auth.auth().currentUser != nil else {return}
       // currentUserId = Auth.auth().currentUser?.uid
       //ref = Database.database().reference()
        mapView.delegate = self
        destinationTextField.delegate = self

        
        centerMapOnUserLocation()
        view.bindtoKeyboard()

        self.loadDriverAnnotationsFromFB()

        DataService.instance.REF_DRIVERS.observe(.value) { (snapshot) in //with: canceled from between .value and snapshot
            self.loadDriverAnnotationsFromFB()
            
            DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    self.zoom(toFitAnnotationsFromMapview: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                }
            })
        }

        
        
        UpdateService.instance.observeDriverTrips { (tripDict) in
            if let tripDict = tripDict{
                let pickupCoordinateArray = tripDict["pickupCoordinate"] as! NSArray
                let tripKey = tripDict["passengerKey"] as! String
                let acceptanceStatus = tripDict["tripIsShared"] as! Bool

                if acceptanceStatus == false{
                    if let id = Auth.auth().currentUser?.uid {
                        DataService.instance.driverIsAvailable(key: id, handler: { (available) in
                            if let available = available {
                                if available == true {
                                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                    let pickupVC = storyboard.instantiateViewController(withIdentifier: "PickupVC") as? LocationSharedViewController
                                    
                                    pickupVC?.initData(coordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees), passengerKey: tripKey)
                                    self.present(pickupVC!, animated: true, completion: nil)
                                }
                            }
                        })
                    }
                }
            }
        }
    }

    
//    // added to check handle erroe of authuser
//    func authUser(user: String, pw: String) {
//    Auth.auth().signIn(withEmail: user, password: pw, completion: { (auth, error) in
//    if let x = error {
//    let err = x as NSError
//    switch err.code {
//    case AuthErrorCode.wrongPassword.rawValue:
//    print("wrong password")
//    case AuthErrorCode.invalidEmail.rawValue:
//    print("invalued email")
//    default:
//    print("unknown error")
//    }
//    } else {
//    if let user = auth?.user {  //note; safely unwrap optional
//    print("uid: \(user.uid)")
//    }
//    }
//    })
//    }
//
 
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if currentUserId == nil || currentUserId == "notLoggedIn" {
            // Set arbitrary userID if userID is nil
            self.currentUserId = "notLoggedIn"
        } else {
            currentUserId = Auth.auth().currentUser?.uid
        }
        
        DataService.instance.userIsDriver(userKey: currentUserId!) { (isDriver) in
            if isDriver == true {
                //self.setButtonsForDriver(hidden: true)
            }
        }
        
        DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                    if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                        for trip in tripSnapshot {
                            if trip.childSnapshot(forPath: "driverKey").value as? String == self.currentUserId! {
                                let pickupCoordinateArray = trip.childSnapshot(forPath: "pickupCoordinate").value as! NSArray
                                let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                                let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                                self.dropPinFor(placemark: pickupPlacemark)
                                self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: pickupPlacemark))
                                //self.setCustomRegion(forAnnotationType: .pickup, withCoordinate: pickupCoordinate)
                                //self.actionForButton = .getDirectionsToPassenger
                                //self.actionBtn.setTitle("GET DIRECTIONS", for: .normal)
                                //self.setButtonsForDriver(hidden: false)
                            }
                        }
                    }
                })
            }
        }
        
        DataService.instance.REF_TRIPS.observe(.childRemoved) { (removedTripSnapshot) in
            if let removedTripDict = removedTripSnapshot.value as? [String: AnyObject] {
                if removedTripDict["driverKey"] != nil {
                    DataService.instance.REF_DRIVERS.child(removedTripDict["driverKey"] as! String).updateChildValues(["driverIsOntrip": false])
                }
                
                DataService.instance.userIsDriver(userKey: self.currentUserId!, handler: { (isDriver) in
                    if isDriver == true {
                        // Remove overlays and annotations
                        // hide request ride button and cancel button
                        self.removeOverlayAndAnnotations(forDrivers: false, forPassengers: true)
                        //self.setButtonsForDriver(hidden: true)
                    } else {
                        self.cancelBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        self.actionBtn.animateButton(shouldLoad: false, withMessage: "REQUEST RIDE")
                        
                        self.destinationTextField.isUserInteractionEnabled = true
                        self.destinationTextField.text = ""
                        self.removeOverlayAndAnnotations(forDrivers: false, forPassengers: true)
                        self.centerMapOnUserLocation()
                    }
                })
            }
        }
        
        connectUserAndDriverForTrip()
        
    }
    
    
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            manager?.startUpdatingLocation()
        }else{
            manager?.requestAlwaysAuthorization()
        }
    }
    
    
    func loadDriverAnnotationsFromFB() {
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.hasChild("coordinate") {
                        if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true {
                            if let driverDict = driver.value as? Dictionary<String, AnyObject> {
                                let coordinateArray = driverDict["coordinate"] as! NSArray
                                let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                
                                let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                
                                var driverIsVisible: Bool {
                                    return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                        if let driverAnnotation = annotation as? DriverAnnotation {
                                            if driverAnnotation.key == driver.key {
                                                driverAnnotation.update(annotationPosition: driverAnnotation, withCoordinate: driverCoordinate)
                                                return true
                                            }
                                        }
                                        return false
                                    })
                                }
                                
                                if !driverIsVisible {
                                    self.mapView.addAnnotation(annotation)
                                }
                            }
                        } else {
                            for annotation in self.mapView.annotations {
                                if annotation.isKind(of: DriverAnnotation.self) {
                                    if let annotation = annotation as? DriverAnnotation {
                                        if annotation.key == driver.key {
                                            self.mapView.removeAnnotation(annotation)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        })
    }

    //interactive driver and passenger v3.4
    func connectUserAndDriverForTrip() {
        if let id = Auth.auth().currentUser?.uid {
            DataService.instance.passengerIsOnTrip(passengerKey: id, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    self.removeOverlayAndAnnotations(forDrivers: false, forPassengers: true)
                    
                    DataService.instance.REF_TRIPS.child(id).observe(.value, with: { (tripSnapshot) in
                        let tripDict = tripSnapshot.value as? [String : AnyObject]
                        let driverId = tripDict?["driverKey"] as! String
                        
                        let pickupCoordinateArray = tripDict?["pickupCoordinate"] as! NSArray
                        let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                        let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                        let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
                        
                        DataService.instance.REF_DRIVERS.child(driverId).child("coordinate").observeSingleEvent(of: .value, with: { (driverSnapshot) in
                            let driverSnapshot = driverSnapshot.value as! NSArray
                            let driverCoordinate = CLLocationCoordinate2D(latitude: driverSnapshot[0] as! CLLocationDegrees, longitude: driverSnapshot[1] as! CLLocationDegrees)
                            let driverPlacemark = MKPlacemark(coordinate: driverCoordinate)
                            let driverMapItem = MKMapItem(placemark: driverPlacemark)
                            
                            let passengerAnnotation = PassengerAnnotation(coordinate: pickupCoordinate, key: id)
                            self.mapView.addAnnotation(passengerAnnotation)
                            
                            self.searchMapKitForResultsWithPolyline(forOriginMapItem: driverMapItem, withDestinationMapItem: pickupMapItem)
                            self.actionBtn.animateButton(shouldLoad: false, withMessage: "DRIVER COMING")
                            self.actionBtn.isUserInteractionEnabled = false
                            
                        })
                        
                        DataService.instance.REF_TRIPS.child(tripKey!).observeSingleEvent(of: .value, with: { (tripSnapshot) in
                            if tripDict?["tripIsShared"] as? Bool == true {
                                self.removeOverlayAndAnnotations(forDrivers: true, forPassengers: true)
                                
                                let destinationCoordinateArray = tripDict?["pickupCoordinate"] as! NSArray
                                let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                                let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                                
                                self.dropPinFor(placemark: destinationPlacemark)
                                self.searchMapKitForResultsWithPolyline(forOriginMapItem: pickupMapItem, withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                                
                                self.actionBtn.setTitle("ON TRIP", for: .normal)
                            }
                        })
                        
                    })
                }
            })
        }
    }
    
    
  
    
    
    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func actionBtnWasPressed(_ sender: Any) {
        UpdateService.instance.updateTripsWithCoordinatesUponRequest()
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
        self.view.endEditing(true)
        destinationTextField.isUserInteractionEnabled = false
    }
    
    @IBAction func cancelBtnWasPressed(_ sender: Any) {
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true{
                UpdateService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
            }
        }
        DataService.instance.passengerIsOnTrip(passengerKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true{
                UpdateService.instance.cancelTrip(withPassengerKey: self.currentUserId!, forDriverKey: driverKey!)
            }else{
                UpdateService.instance.cancelTrip(withPassengerKey: self.currentUserId!, forDriverKey: nil)
            }
            self.actionBtn.isUserInteractionEnabled = true
        }
        //resetDestinationSearchField()
    }
    
    
    
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        if let id = Auth.auth().currentUser?.uid {
            DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
                if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for user in userSnapshot {
                        if user.key == id {
                            if user.hasChild("tripCoordinate") {
                                self.zoom(toFitAnnotationsFromMapview: self.mapView, forActiveTripWithDriver: false, withKey: nil)
                                self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                            } else {
                                self.centerMapOnUserLocation()
                                self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                            }
                        }
                    }
                }
            })
        }
    }
    

    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }

}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedAlways{
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
            
        }
    }
}

extension MainViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
        
        DataService.instance.userIsDriver(userKey: currentUserId!) { (isDriver) in
            if isDriver == true {
                DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true {
                        self.zoom(toFitAnnotationsFromMapview: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                    } else {
                        self.centerMapOnUserLocation()
                    }
                })
            } else {
                DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true {
                        self.zoom(toFitAnnotationsFromMapview: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                    } else {
                        self.centerMapOnUserLocation()
                    }
                })
            }
        }
        
        
        
        
}
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? DriverAnnotation{
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "Icon-29") //image icon for the Bus/driver location
            return view
        } else if let annotation = annotation as? PassengerAnnotation {
            let identifier = "passenger"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "currentLocationAnnotation") //pin for the current location
            return view
        } else if let annotation = annotation as? MKPointAnnotation
        {
            let identifier = "destination"
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
        return nil
    }
    
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    //this function is to show the route of the destination and color
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let lineRenderer = MKPolylineRenderer(overlay: self.route.polyline)
        //to color the route
        lineRenderer.strokeColor = UIColor(red: 0.5882, green: 0.5176, blue: 1, alpha: 0.8)
        //lineRenderer.strokeColor = UIColor(displayP3Red: 216/255, green: 100/255, blue: 30/255, alpha: 0.75)
        lineRenderer.lineWidth = 5
        lineRenderer.lineJoin = .round
        
        shouldPresentLoadingView(false)
        zoom(toFitAnnotationsFromMapview: self.mapView, forActiveTripWithDriver: false, withKey: nil)
        return lineRenderer
    }
    
    
    //is responsible for a ll the search related erro4
    func performSearch() {
        matchingItems.removeAll()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        
        search.start { (response, error) in
            if error != nil
            {
                self.showAlert("Unexpected Error, Could't Handle!")
            }
            else if response!.mapItems.count == 0{
                self.showAlert("Error! No Matches Found")
            }
            else{
                for mapItem in response!.mapItems{
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
        }
    }
        func dropPinFor(placemark : MKPlacemark) {
            
            selectedItemPlacemark = placemark
            
            for annotation in mapView.annotations{
                if annotation.isKind(of: MKPointAnnotation.self)
                {
                    mapView.removeAnnotation(annotation)
                }
            }
            
            let annotation = MKPointAnnotation()
            
            annotation.coordinate = placemark.coordinate
            mapView.addAnnotation(annotation)
        }

    func searchMapKitForResultsWithPolyline(forOriginMapItem originMapItem: MKMapItem?, withDestinationMapItem destinationMapItem: MKMapItem) {
        let request = MKDirections.Request()
        
        if originMapItem == nil {
            request.source = MKMapItem.forCurrentLocation()
        } else {
            request.source = originMapItem
        }
        
        request.destination = destinationMapItem
        request.transportType = MKDirectionsTransportType.automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            guard let response = response else {self.showAlert("There has been an unexpected error. Please try again."); return}
            self.route = response.routes[0]
            
            self.mapView.addOverlay(self.route!.polyline)
            
            self.zoom(toFitAnnotationsFromMapview: self.mapView, forActiveTripWithDriver: false, withKey: nil)
            
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController?.shouldPresentLoadingView(false)
        }
    }
    
    func zoom(toFitAnnotationsFromMapview mapView: MKMapView, forActiveTripWithDriver: Bool, withKey key: String?) {
        if mapView.annotations.count == 0 {
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        if forActiveTripWithDriver {
            for annotation in mapView.annotations {
                if let annotation = annotation as? DriverAnnotation {
                    if annotation.key == key {
                        
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                } else {
                    
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0))
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }

    
    func removeOverlayAndAnnotations(forDrivers: Bool?, forPassengers: Bool?) {
        for annotation in mapView.annotations {
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
            
            if forPassengers! {
                if let annotation = annotation as? PassengerAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
            if forDrivers! {
                if let annotation = annotation as? DriverAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
        
        for overlay in mapView.overlays {
            if overlay is MKPolyline {
                mapView.removeOverlay(overlay)
            }
        }
    }
}

extension MainViewController : UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == destinationTextField
        {    //because button is 10 from edge. That is why we subtract 20.
            tableView.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 170)
            tableView.layer.cornerRadius = 5.0
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellLocation")
            
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.tag = 18
            tableView.rowHeight = 45 //individual size of tableview
            
            view.addSubview(tableView)
            animateTableView(shouldShow: true)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == destinationTextField
        {
            performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField == destinationTextField
        {
            if destinationTextField.text == ""
            {
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircle.backgroundColor = UIColor.lightGray
                   self.destinationCircle.borderColor = UIColor.darkGray
                })
            }
        }
    }
    
    
    
    //remove passenger annotation and remove all overlays
    //remove selected and searched text filed from searchbar
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableView.reloadData()
        
        if let id = Auth.auth().currentUser?.uid {
            DataService.instance.REF_USERS.child(id).child("tripCoordinate").removeValue()
        }
        
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations {
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            } else if annotation.isKind(of: PassengerAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        centerMapOnUserLocation()
        
        return true
    }
    
    //to animate table view while user selecting
    func animateTableView(shouldShow : Bool) {
        
        if shouldShow
        {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: 210, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            })
        }
        else
        {
            UIView.animate(withDuration: 0.2, animations: {
                
                self.tableView.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
                
            }, completion: { (finished) in
                
                for subview in self.view.subviews
                {
                    if subview.tag == 18
                    {
                        subview.removeFromSuperview()
                    }
                }
            })
        }
    }
}

extension MainViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellLocation")
        let mapItem = matchingItems[indexPath.row]
        
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        shouldPresentLoadingView(true)
        
        let passengerCoordinate = manager?.location?.coordinate
        if let id = Auth.auth().currentUser?.uid {
            let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, key: id)
            mapView.addAnnotation(passengerAnnotation)
            
            destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
            
            let selectedMapItem = matchingItems[indexPath.row]
            
            DataService.instance.REF_USERS.child(id).updateChildValues(["tripCoordinate" : [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])
            
            dropPinFor(placemark: selectedMapItem.placemark)
            
            searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: selectedMapItem)
            
            animateTableView(shouldShow: false)
            print("selected cell")
            
        }
    }
    
    
    //when scrolled editing is finished 
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    //hide the scroll view
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        if destinationTextField.text == ""
        {
            animateTableView(shouldShow: false)
        }
    }
}

