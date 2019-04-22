//
//  RoundedCornerTextField.swift
//  Live Bus Time
//
//  Created by Kabir on 20/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit

class RoundedCornerTextField: UITextField {

    
    var textRectOffset : CGFloat = 20
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        
        self.layer.cornerRadius = self.frame.height / 2
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        
        return CGRect(x: 0 + textRectOffset, y: 0 + (textRectOffset / 2), width: self.frame.width - textRectOffset, height: self.frame.height + textRectOffset)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        
        return CGRect(x: 0 + textRectOffset, y: 0 + (textRectOffset / 2), width: self.frame.width - textRectOffset, height: self.frame.height + textRectOffset)
    }
}
