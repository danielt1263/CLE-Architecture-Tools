//
//  UIColorExtensions.swift
//
//  Created by Daniel Tartaglia on 4 Dec 2014.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import UIKit


public extension UIColor {

	convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
		let red   = (hex & 0xFF0000) >> 16
		let green = (hex & 0x00FF00) >>  8
		let blue  = (hex & 0x0000FF)
		let max: CGFloat = 255
		self.init(red: CGFloat(red)/max, green: CGFloat(green)/max, blue: CGFloat(blue)/max, alpha: alpha)
	}

}
