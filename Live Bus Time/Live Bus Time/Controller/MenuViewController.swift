//
//  LeftSidePanelVC.swift
//  Live Bus Time
//
//  Created by Kabir on 19/03/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit
import Firebase

class MenuViewController: UIViewController {
    
    //let currentUserId = Auth.auth().currentUser?.uid
    let appDelegate = AppDelegate.getAppDelegate()

    @IBOutlet weak var userImageView: RoundImageView!
    @IBOutlet weak var pickUpModeSwitch: UISwitch!
    @IBOutlet weak var pickUpModeLbl: UILabel!
    @IBOutlet weak var userEmailLbl: UILabel!
    @IBOutlet weak var userAccountTypeLbl: UILabel!
    @IBOutlet weak var loginOutBtn: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickUpModeSwitch.isOn = false
        pickUpModeSwitch.isHidden  = true //false in the vd
        pickUpModeLbl.isHidden = true
        
        
        observePassengersAndDrivers()
    
        if Auth.auth().currentUser == nil {
            userEmailLbl.text = ""
            userAccountTypeLbl.text = ""
            userImageView.isHidden = true
            loginOutBtn.setTitle("Sign Up / Login", for: .normal)
            
        } else {
            userEmailLbl.text = Auth.auth().currentUser?.email
            userAccountTypeLbl.text = ""
            userImageView.isHidden = false 
            loginOutBtn.setTitle("LogOut", for: .normal)
        }
    }
    
    //check if its a driver or passenger
    func observePassengersAndDrivers() {
        
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            //capturing all children of users node, and all objects beneath
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = "Passenger"
                    }
                }
            }
        })
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = "Driver"
                        self.pickUpModeSwitch.isHidden = false
                        
                        let switchStatus = snap.childSnapshot(forPath: "IsPickupModeEnabled").value as! Bool
                        self.pickUpModeSwitch.isOn = switchStatus
                        self.pickUpModeLbl.isHidden = false
                    }
                }
            }
        })
    }
    //check the pickup mode enableb with Firebase
    @IBAction func switchIsOn(_ sender: Any) {
        if pickUpModeSwitch.isOn {
            pickUpModeLbl.text = "Location Enabled"
            if let currentUserId = Auth.auth().currentUser?.uid {
                appDelegate.MenuContainerVC.toggleLeftPanel()
                DataService.instance.REF_DRIVERS.child(currentUserId).updateChildValues(["IsPickupModeEnabled" : true])
                //Have to implement func to updatevalue on driver when logging in, since login by default is pickupmodedisabled.
            }
        } else {
            pickUpModeLbl.text = "Location Disabled"
            if let currentUserId = Auth.auth().currentUser?.uid {
                appDelegate.MenuContainerVC.toggleLeftPanel()
                DataService.instance.REF_DRIVERS.child(currentUserId).updateChildValues(["IsPickupModeEnabled" : false])
            }
        }
    }
    
    
    
    @IBAction func LoginBtnWasPressed(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? SignUpViewController
            present(loginVC!, animated: true, completion: nil)
        } else {
            do {
                try Auth.auth().signOut()
                userEmailLbl.text = ""
                userAccountTypeLbl.text = ""
                pickUpModeLbl.text = ""
                userImageView.isHidden = true
                pickUpModeSwitch.isHidden = true
                loginOutBtn.setTitle("Sign Up / Login", for: .normal)
            } catch (let error) {
                print(error)
            }
        }
    }
    /*
     //   MARK: - Navigation
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
