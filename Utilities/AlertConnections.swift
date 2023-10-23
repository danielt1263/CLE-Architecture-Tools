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
	/**
	 This method is usesd inside the `scene(_:)` closure to set up an alert with a single button. The caller will be
	 notified when the button is tapped.
	
	 - parameter buttonTitle: title of the single button that the alert will display.
	 - returns: An Observable that will emit a next event and complete when the user taps the button.
	 */
	func connectOK(buttonTitle: String = "OK") -> Observable<Void> {
		connect(buttons: [ButtonType(title: buttonTitle, style: .default, action: { _ in () })])
	}

	/**
	 This method is used inside thte `scene(_:)` closure to set up an alert with a number of buttons equal to
	 `choices.count` as well as a Cancel button. The caller will be notified which button was tapped.

	 - parameter choices: The items thte user will be able to choose from.
	 - parameter description: A closure that provides the title for a particular choice's button.
	 - parameter cancelTitle: The title of thte cancel button.
	 - parameter customizeActions: A closure that allows the caller to customise the UIAlertAction for a particular
	 choice.
	 - parameter customizeCancel: A closure that allows the caller to customise the UIAlertAction for the cancel button.
	 - returns: An Observable that will emit a next event with the choice the user made (or nil if the user chose
	 Cancel) and complete when the user taps the button.
	 */
	func connectChoice<T>(choices: [T],
						  description: (T) -> String = { String(describing: $0) },
						  cancelTitle: String = "Cancel",
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
		let cancel = ButtonType<T?>(title: cancelTitle, style: .cancel, action: { _ in nil }, customize: customizeCancel)
		return connect(buttons: buttons + [cancel])
	}
}

extension UIAlertController {
	/**
	 A type for describing a button on a UIAlertController.
	 - The `action` parameter should be supplied with a closure describing what the alert's Observable should emit when
	 the user taps on this button. The action is supplied with the string values of any text fields that might have
	 been applied to the alert.
	 - The `customize` parameter gives the caller a chance to make adjustments to the UIAlertAction before it is
	 attatched to the Alert.
	 */
	public struct ButtonType<Action> {
		public let title: String
		public let style: UIAlertAction.Style
		public let action: ([String]) -> Action
		public var customize: (UIAlertAction) -> Void = { _ in }

		public init(title: String,
					style: UIAlertAction.Style,
					action: @escaping ([String]) -> Action,
					customize: @escaping (UIAlertAction) -> Void = { _ in }) {
			self.title = title
			self.style = style
			self.action = action
			self.customize = customize
		}
	}

	/**
	 This method is used inside the `scene(_:)` closure to set up an alert with a number of buttons described by the
	 `buttons` array, and a number of text fields described by the `fields` array. The caller will be notified when a
	 button is tapped by receiving the `Action` that was associated with that button.

	 - parameter buttons: Each ButtonType object will be associated with a button on the alert.
	 - parameter fields: Each closure passed will cause a text field to be added to the alert. The closure gives the
	 caller a chance to make adjustments to the text field before being added.
	 - returns: An Observable that will emit a next event with the result of calling the `action` closure associated
	 with the button tapped and then complete.
	 */
	public func connect<Action>(buttons: [ButtonType<Action>] = [],
								fields: [(UITextField) -> Void] = []) -> Observable<Action> {
		let action = PublishSubject<Action>()
		let alertActions = buttons.map { button in
			let action = UIAlertAction(title: button.title, style: button.style) { [textFields] _ in
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
