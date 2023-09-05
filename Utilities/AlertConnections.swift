//
//  AlertConnections.swift
//
//  Created by Daniel Tartaglia on 06 Nov 2020.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift
import UIKit

public extension UIAlertController {
	func connectOK(buttonTitle: String = "OK") -> Observable<Void> {
		connect(buttons: [ButtonType(title: buttonTitle, style: .default, action: { _ in () })])
	}

	func connectChoice<T>(choices: [T],
						  description: (T) -> String = { String(describing: $0) },
						  customizeActions: @escaping (UIAlertAction) -> Void = { _ in },
						  customizeCancel: @escaping (UIAlertAction) -> Void = { _ in }) -> Observable<T?> {
		let buttons = choices.map { choice in
			ButtonType<T?>(
				title: description(choice),
				style: .default,
				action: { _ in choice },
				customize: customizeActions
			)
		}
		let cancel = ButtonType<T?>(title: "Cancel", style: .cancel, action: { _ in nil }, customize: customizeCancel)
		return connect(buttons: buttons + [cancel])
	}
}

extension UIAlertController {
	struct ButtonType<Action> {
		let title: String
		let style: UIAlertAction.Style
		let action: ([String]) -> Action
		var customize: (UIAlertAction) -> Void = { _ in }
	}

	func connect<Action>(buttons: [ButtonType<Action>] = [],
						 fields: [(UITextField) -> Void] = []) -> Observable<Action> {
		let action = PublishSubject<Action>()
		let alertActions = buttons.map { button in
			let action = UIAlertAction(title: button.title, style: button.style) { [textFields] alertAction in
				let texts = (textFields ?? []).map { $0.text ?? "" }
				action.onSuccess(button.action(texts))
			}
			button.customize(action)
			return action
		}
		for field in fields {
			addTextField(configurationHandler: field)
		}
		for alertAction in alertActions {
			addAction(alertAction)
		}
		return action
	}
}
