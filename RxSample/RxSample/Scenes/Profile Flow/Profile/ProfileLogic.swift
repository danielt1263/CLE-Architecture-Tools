//
//  ProfileLogic.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

enum ProfileLogic {

	static func infoFor(user: Observable<User?>, keyPath: KeyPath<User, String>) -> Observable<String> {
		user.map { $0.map { $0[keyPath: keyPath] } ?? "" }
	}

}

extension User {
	var initials: String {
		return name.split(separator: " ")
			.compactMap { $0.first.map { String($0) } }
			.joined()
	}
}
