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
        //currentUserId = Auth.auth().currentUser?.uid
       // ref = Database.database().reference()
        mapView.delegate = self
        destinationTextField.delegate = self

        
        centerMapOnUserLocation()
        view.bindtoKeyboard()

        self.loadDriverAnnotationsFromFB()

        DataService.instance.REF_DRIVERS.observe(.value, with: { (snapshot) in
            self.loadDriverAnnotationsFromFB()
        })
        
        
        UpdateService.instance.observeDriverTrips { (tripDict) in
            if let tripDict = tripDict{
                let pickupCoordinateArray = tripDict["pickupCoordinate"] as! NSArray
                let tripKey = tripDict["passengerKey"] as! String
                let acceptanceStatus = tripDict["tripIsShared"] as! Bool

                if acceptanceStatus == false
                {
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
                        if driver.childSnapshot(forPath: "IsPickupModeEnabled").value as? Bool == true {
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
    
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        if let id = Auth.auth().currentUser?.uid {
            DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
                if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for user in userSnapshot {
                        if user.key == id {
                            if user.hasChild("tripCoordinate") {
                                self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
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
}
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? DriverAnnotation
        {
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "Icon-29") //image icon for the Bus/driver location
            return view
        }
        else if let annotation = annotation as? PassengerAnnotation {
            let identifier = "passenger"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "currentLocationAnnotation") //pin for the current location
            return view
        }
        else if let annotation = annotation as? MKPointAnnotation
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
        //lineRenderer.lineJoin = .round
        
        shouldPresentLoadingView(false)
        
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
            else if response!.mapItems.count == 0
              {
                self.showAlert("Error! No Matches Found")
            }
            else
            {
                for mapItem in response!.mapItems
                {
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
        }
    }
        func dropPinFor(placemark : MKPlacemark) {
            
            selectedItemPlacemark = placemark
            
            for annotation in mapView.annotations
            {
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
        
        if originMapItem == nil
        {
            request.source = MKMapItem.forCurrentLocation()
        }
        else
        {
            request.source = originMapItem
        }
        
        request.destination = destinationMapItem
        request.transportType = MKDirectionsTransportType.automobile //set the transport type
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            
            guard let response = response else {
                
                self.showAlert(error.debugDescription)
                return
            }
            self.route = response.routes[0]
            
            self.mapView.addOverlay(self.route!.polyline)
            //self.mapView.addOverlay(self.route!.distance) // to show the distance as well

            
            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController?.shouldPresentLoadingView(false) // Loading view (Activity Indicator)
        }
    }

    
    func zoom(toFitAnnotationsFromMapView mapView : MKMapView, forActiveTripWithDriver: Bool, withKey key: String?) {
        
        if mapView.annotations.count == 0
        {
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        if forActiveTripWithDriver
        {
            for annotation in mapView.annotations
            {
                if let annotation = annotation as? DriverAnnotation
                {
                    if annotation.key == key
                    {
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                }
                else
                {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self)
        {
            //we are creating a radius that includes the passenger and driver annotation.
            //funcs below return the smaller and bigger of both of theese values and create a perfect rectangle that contains both passenger
            //pickup point and destination point.
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

