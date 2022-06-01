//
//  LoginConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import EnumKit
import RxCocoa
import RxSwift
import UIKit

extension LoginViewController {
	func connect() -> Observable<Void> {

		let credentials = Observable.combineLatest(emailTextField.rx.text.orEmpty, passwordTextField.rx.text.orEmpty) { (email: $0, password: $1) }
		let response = loginButton.rx.tap
			.withLatestFrom(credentials)
			.flatMapLatest { _ in
				api.response(.getUser(id: 1))
			}
			.share(replay: 1)

		response
			.bind(onNext: save(user:))
			.disposed(by: disposeBag)

		api.isActive
			.bind(to: activityIndicatorView.rx.isAnimating)
			.disposed(by: disposeBag)

		return signupButton.rx.tap
			.take(until: rx.deallocating)
	}
}

enum AuthenticationError: Error {
	case invalidCredentials
}
