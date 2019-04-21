//
//  LeftSidePanelVC.swift
//  Live Bus Time
//
//  Created by Kabir on 19/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit

class LeftSidePanelVC: UIViewController {

    @IBOutlet weak var userAccountTypeLbl: UILabel!
    @IBOutlet weak var userEmailLbl: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var loginOutBtn: UIButton!
    @IBOutlet weak var pickUpModeSwitch: UISwitch!
    @IBOutlet weak var pickUpModeLbl: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickUpModeSwitch.isOn = false
        pickUpModeSwitch.isHidden  = false
        pickUpModeLbl.isHidden = true
    }
    
    //check if its a driver or passenger
    func observeDriversAndPassengers() {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLabel.text = "PASSENGER"
                    }
                }
            }
        })
    
    @IBAction func LoginBtnWasPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
        present(loginVC!, animated: true, completion: nil)


    }
    
}
