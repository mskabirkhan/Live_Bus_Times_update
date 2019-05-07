//
//  UIViewControllerExt.swift
//  Live Bus Time
//
//  Created by Kabir on 03/03/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit

//extension for to show the loading view icon while map is loading or searching
extension UIViewController {
    func shouldPresentLoadingView(_ status: Bool) {
        var fadeView: UIView?
        
        if status == true{
            fadeView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
            fadeView?.backgroundColor = UIColor.black
            fadeView?.alpha = 0.0
            // Arbitrary number set to tag to identify subview later (for removal)
            fadeView?.tag = 99
            
            let spinner = UIActivityIndicatorView()
            spinner.color = .white
            spinner.style = .whiteLarge
            spinner.center = view.center
            
            view.addSubview(fadeView!)
            fadeView?.addSubview(spinner)
            
            spinner.startAnimating()
            
            fadeView?.fadeTo(alphaValue: 0.7, withDuration: 0.3)
        }
        else{
            for subview in view.subviews{
                if subview.tag == 99{
                    UIView.animate(withDuration: 0.2, animations: {
                        subview.alpha = 0.0
                    }, completion: { (finished) in
                        
                        subview.removeFromSuperview()
                    })
                }
            }
        }
    }
}
