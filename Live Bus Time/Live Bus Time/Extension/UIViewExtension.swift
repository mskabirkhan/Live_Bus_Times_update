//
//  UIViewExtension.swift
//  Live Bus Time
//
//  Created by Kabir on 20/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit
extension UIView{
    func fadeTo(alphaValue : CGFloat, withDuration duration : TimeInterval) {
        
        UIView.animate(withDuration: duration) {
            
            self.alpha = alphaValue
        }
    }

//    func bindtoKeyboard() {
//        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(keyboardWillChange(_:)), name: NSNotification.Name.keyboardWillChange,   object: nil) //You can use any subclass of UIResponder too
//    }
    
    @objc func keyboardWillChange(_ notification : NSNotification) {
        
        let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as!Double
        let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
        let curFrame = (notification.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let targetFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let deltaY = targetFrame.origin.y - curFrame.origin.y
        
        UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: UIView.KeyframeAnimationOptions(rawValue : curve), animations: {
            
            self.frame.origin.y += deltaY
            
        }, completion: nil)
    }



}