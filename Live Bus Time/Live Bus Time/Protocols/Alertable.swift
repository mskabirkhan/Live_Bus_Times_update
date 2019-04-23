//
//  Alertable.swift
//  Live Bus Time
//
//  Created by Kabir on 23/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit

protocol Alertable {}

extension Alertable where Self : UIViewController {
    
    func showAlert(_ msg : String) {
        
        let alertController = UIAlertController(title: "Error!", message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
}
