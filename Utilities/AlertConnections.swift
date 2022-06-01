//
//  AlertConnections.swift
//
//  Created by Daniel Tartaglia on 11/6/2020.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift
import UIKit

public extension UIAlertController {
	func connectOK(buttonTitle: String = "OK") -> Observable<Void> {
		let action = PublishSubject<Void>()
		addAction(UIAlertAction(title: buttonTitle, style: .default, handler: { _ in
			action.onSuccess(())
		}))
		return action
	}

	func connectChoice<T>(choices: [T], description: (T) -> String = { String(describing: $0) }, customizeActions: (UIAlertAction) -> Void = { _ in }, customizeCancel: (UIAlertAction) -> Void = { _ in }) -> Observable<T?> {
		let action = PublishSubject<T?>()

		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in action.onSuccess(nil) })
			.setup(customizeCancel)

		let actions = choices.map { element in
			UIAlertAction(title: description(element), style: .default, handler: { _ in action.onSuccess(element) })
				.setup(customizeActions)
		}

		for action in actions + [cancelAction] {
			addAction(action)
		}

		return action
	}
}
