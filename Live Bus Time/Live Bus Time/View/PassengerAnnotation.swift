//
//  PassengerAnnotation.swift
//  Live Bus Time
//
//  Created by Kabir on 23/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import Foundation
import MapKit

class PassengerAnnotation : NSObject, MKAnnotation {
    dynamic var coordinate : CLLocationCoordinate2D
    var key : String
    
    init(coordinate : CLLocationCoordinate2D, key : String) {
        
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
}
