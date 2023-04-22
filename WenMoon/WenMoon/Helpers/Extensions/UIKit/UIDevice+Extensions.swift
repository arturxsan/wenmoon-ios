//
//  UIDevice+Extensions.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 31.03.25.
//

import UIKit.UIDevice

extension UIDevice {
    var isSmallScreen: Bool {
        UIScreen.main.bounds.height <= 812
    }
    
    var isSemiSmallScreen: Bool {
        UIScreen.main.bounds.height <= 812
    }
}
