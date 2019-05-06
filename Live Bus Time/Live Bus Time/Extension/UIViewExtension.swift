//
//  UIViewExtension.swift
//  Live Bus Time
//
//  Created by Kabir on 1/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit

//an extension of UITable view for keyboard to fadein while poping
extension UIView{
    func fadeTo(alphaValue : CGFloat, withDuration duration : TimeInterval) {
        UIView.animate(withDuration: duration) {
            self.alpha = alphaValue
        }
    }

    func bindtoKeyboard() {
            NotificationCenter.default.addObserver(self, selector: #selector(UIView.keyboardWillChange(_:)), name:
                UIApplication.keyboardWillChangeFrameNotification
                , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillChange(_ notification : NSNotification) {
        // Store the duration of the animation from the keyboard popping up
        let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as!Double
        // Use the same easing in and out curving properties as the keyboard animation
        let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
        let curFrame = (notification.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let targetFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let deltaY = targetFrame.origin.y - curFrame.origin.y
        
        UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: UIView.KeyframeAnimationOptions(rawValue : curve), animations: {
            
            self.frame.origin.y += deltaY
            
        }, completion: nil)
    }



}
