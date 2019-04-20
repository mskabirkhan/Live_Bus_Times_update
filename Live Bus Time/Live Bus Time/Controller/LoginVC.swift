//
//  LoginVC.swift
//  Live Bus Time
//
//  Created by Kabir on 20/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //view.bindtoKeyboard()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tap)
        
    }
    
    @objc func handleScreenTap(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    @IBAction func CancelBtnWaspressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
