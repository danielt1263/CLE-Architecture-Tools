//
//  ProfileConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift
import RxCocoa

extension ProfileViewController {
	func connect() -> Observable<Void> {

		ProfileLogic.infoFor(user: user, keyPath: \.initials)
			.bind(to: avatarLabel.rx.text)
			.disposed(by: disposeBag)

		ProfileLogic.infoFor(user: user, keyPath: \.name)
			.bind(to: nameLabel.rx.text)
			.disposed(by: disposeBag)

		ProfileLogic.infoFor(user: user, keyPath: \.username)
			.bind(to: usernameLabel.rx.text)
			.disposed(by: disposeBag)

		return settingsButtonItem.rx.tap
			.take(until: rx.deallocated)
	}
}
