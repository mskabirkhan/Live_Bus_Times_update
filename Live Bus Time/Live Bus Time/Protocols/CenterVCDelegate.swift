//
//  CenterVCDelegate.swift
//  Live Bus Time
//
//  Created by Kabir on 19/04/2019.
//  Copyright © 2019 Kabir. All rights reserved.
//

import UIKit

protocol CenterVCDelegate {
    
    func toggleLeftPanel()
    func addLeftPanelViewController()
    func animateLeftPanel(shouldExpand: Bool) //when is passing true its anymate
}
