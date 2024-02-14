//
//  LoginNavigation.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxSwift
import UIKit

func loginNavigation() -> Scene<Never> {
	let root = LoginViewController().scene { $0.connect() }
	let navigation = UINavigationController(rootViewController: root.controller)
	navigation.modalPresentationStyle = .fullScreen
	navigation.modalTransitionStyle = .crossDissolve

	let signUpResult = root.action
		.flatMapFirst(navigation.pushScene(animated: true) {
			SignupViewController().scene { $0.connect() }
		})

	return Scene(controller: navigation, action: signUpResult.take(until: user.filter { $0 != nil }))
}
