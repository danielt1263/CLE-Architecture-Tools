//
//  SignupConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift
import UIKit

extension SignupViewController {
	func connect() -> Observable<Never> {

		let response = SignupLogic.signUp(
			trigger: signupButton.rx.tap.asObservable(),
			firstName: firstNameTextField.rx.text.asObservable(),
			lastName: lastNameTextField.rx.text.asObservable(),
			email: emailTextField.rx.text.asObservable(),
			password: passwordTextField.rx.text.asObservable()
		)
		.flatMap { request -> Observable<User> in
			apiResponse(from: request)
		}
		.share(replay: 1)

		response
			.bind(onNext: save(user:))
			.disposed(by: disposeBag)

		activityIndicator.asObservable()
			.bind(to: activityIndicatorView.rx.isAnimating)
			.disposed(by: disposeBag)

		return Observable.never()
			.take(until: rx.deallocating)
	}
}
