//
//  SignupLogic.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

enum SignupLogic {

	static func signUp(
		trigger: Observable<Void>,
		firstName: Observable<String?>,
		lastName: Observable<String?>,
		email: Observable<String?>,
		password: Observable<String?>
	) -> Observable<Endpoint<User>> {
		let signupParams = Observable.combineLatest(
			firstName.map { $0 ?? "" },
			lastName.map { $0 ?? "" },
			email.map { $0 ?? "" },
			password.map { $0 ?? "" }
		) { (firstName: $0, lastName: $1, email: $2, password: $3) }

		return trigger
			.withLatestFrom(signupParams)
			.map { _ in .getUser(id: 1) }
	}
	
}
