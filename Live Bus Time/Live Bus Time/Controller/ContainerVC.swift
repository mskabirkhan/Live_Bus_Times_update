//
//  ContainerVC.swift
//  Live Bus Time
//
//  Created by Kabir on 19/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit
import QuartzCore
//wheather or not manu is expanded or collasped
enum SliderOutState {
    case collapsed
    case leftPanelExpanded
}

//to show the homeVC
enum ShowWhichVC {
    case homeVC
}

var showVC : ShowWhichVC = .homeVC      //to show default screen
class ContainerVC: UIViewController {
    var homeVC : MainViewController!
    var leftVC : MenuViewController!
    var centerController : UIViewController!
    var currentState : SliderOutState = .collapsed {
        didSet{
            let shouldShowShadow = (currentState != .collapsed)
            shouldShowShadowForCenterViewController(status: shouldShowShadow)
        }
    }
    
    var isHidden = false
    let centerPanelExpandedOffset : CGFloat = 160
    var tap : UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCenter(screen: showVC)
    }
    
    
    //intialiser the view controller in the centre
    func initCenter(screen : ShowWhichVC) {
        var presentingController : UIViewController
        showVC = screen
        if homeVC == nil{
            homeVC = UIStoryboard.mainVC()
            homeVC.delegate = self
        }
        
        presentingController = homeVC
        
        // Remove controller, so that we won't make several copies and waste resources
        if let con = centerController{
            con.view.removeFromSuperview()
            con.removeFromParent()
        }
        
        centerController = presentingController
        view.addSubview(centerController.view)
        addChild(centerController)
        centerController.didMove(toParent: self)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return isHidden
    }
}

extension ContainerVC : CenterVCDelegate {
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .leftPanelExpanded)
        if notAlreadyExpanded{
            addLeftPanelViewController()
        }
        animateLeftPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func addLeftPanelViewController() {
        
        if leftVC == nil{
            leftVC = UIStoryboard.leftViewController()
            addChildSidePanelViewController(leftVC!)
        }
    }
    
    func addChildSidePanelViewController(_ sidePanelController: MenuViewController) {
        view.insertSubview(sidePanelController.view, at: 0)
        addChild(sidePanelController)
        sidePanelController.didMove(toParent: self)
    }
    
    @objc func animateLeftPanel(shouldExpand: Bool) {
        if shouldExpand
        {
            isHidden = !isHidden
            animateStatusBar()
            
            setupWhiteCoverView()
            currentState = .leftPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: centerController.view.frame.width - centerPanelExpandedOffset)
        }
        else{
            isHidden = !isHidden
            animateStatusBar()
            hideWhiteCoverView()
            animateCenterPanelXPosition(targetPosition: 0, completion: { (finished) in
                if finished == true{
                    self.currentState = .collapsed
                    self.leftVC = nil
                }
            })
        }
    }
    
    func animateCenterPanelXPosition(targetPosition : CGFloat, completion : ((Bool) -> Void)! = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centerController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
    func setupWhiteCoverView() {
        let whiteCoverView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        whiteCoverView.alpha = 0.0
        whiteCoverView.backgroundColor = UIColor.white
        whiteCoverView.tag = 25
        self.centerController.view.addSubview(whiteCoverView)
        UIView.animate(withDuration: 0.2){
            whiteCoverView.alpha = 0.85
        }
        
        tap = UITapGestureRecognizer(target: self, action: #selector(animateLeftPanel(shouldExpand:)))
        tap.numberOfTapsRequired = 1
        self.centerController.view.addGestureRecognizer(tap)
    }
    
    func hideWhiteCoverView() {
        centerController.view.removeGestureRecognizer(tap)
        for subview in self.centerController.view.subviews
        {
            if subview.tag == 25
            {
                UIView.animate(withDuration: 0.2, animations: {
                    
                    subview.alpha = 0.0
                    
                }, completion: { (finished) in
                    
                    subview.removeFromSuperview()
                })
            }
        }
    }
    
    func shouldShowShadowForCenterViewController(status : Bool) {
        if status == true
        {
            centerController.view.layer.shadowOpacity = 0.6
        }
        else
        {
            centerController.view.layer.shadowOpacity = 0.0
        }
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
}

private extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
    
    class func leftViewController() -> MenuViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier: "LeftSidePanelVC") as? MenuViewController
    }
    
    class func mainVC() -> MainViewController? {
        return mainStoryboard().instantiateViewController(withIdentifier: "HomeVC") as? MainViewController
    }
}
