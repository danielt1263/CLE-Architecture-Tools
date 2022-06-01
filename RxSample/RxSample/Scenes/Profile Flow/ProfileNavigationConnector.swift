//
//  ProfileNavigationConnection.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 12/28/20.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxCocoa
import RxSwift
import UIKit

extension UINavigationController {
	func connectProfile() {
		let profile = ProfileViewController.scene { $0.connect() }
		viewControllers = [profile.controller]

		let logout = profile.action
			.flatMapFirst(presentScene(animated: true) {
				SettingsViewController.scene { $0.connect() }
			})

		_ = logout
			.bind(onNext: {
				deleteUser()
			})
	}
}
