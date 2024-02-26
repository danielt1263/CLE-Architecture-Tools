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
		connect(buttons: [ButtonType(title: buttonTitle, action: { _ in () })])
	}

	/**
	 This method is used inside thte `scene(_:)` closure to set up an alert with a number of buttons equal to
	 `choices.count` as well as a Cancel button. The caller will be notified which button was tapped.

	 - parameter choices: The items thte user will be able to choose from.
	 - parameter description: A closure that provides the title for a particular choice's button.
	 - parameter cancelTitle: The title of thte cancel button. If empty, then no cancel button will be included.
	 - parameter customizeActions: A closure that allows the caller to customise the UIAlertAction for a particular
	 choice.
	 - parameter customizeCancel: A closure that allows the caller to customise the UIAlertAction for the cancel button.
	 - returns: An Observable that will emit a next event with the choice the user made (or nil if the user chose
	 Cancel) and complete when the user taps the button.
	 */
	func connectChoice<T>(choices: [T],
	                      description: (T) -> String = { String(describing: $0) },
	                      cancelTitle: String = "",
	                      customizeActions: @escaping (UIAlertAction) -> Void = { _ in },
	                      customizeCancel: @escaping (UIAlertAction) -> Void = { _ in }) -> Observable<T?>
	{
		let buttons = choices.map { choice in
			ButtonType<T?>(
				title: description(choice),
				action: { _ in choice },
				customize: customizeActions
			)
		}
		let cancel = cancelTitle.isEmpty ? [] : [
			ButtonType<T?>(title: cancelTitle, style: .cancel, action: { _ in nil }, customize: customizeCancel),
		]
		return connect(buttons: buttons + cancel)
	}
}

public extension UIAlertController {
	struct ButtonType<Action> {
		public let title: String
		public let style: UIAlertAction.Style
		public let action: ([String]) -> Action
		public var customize: (UIAlertAction) -> Void = { _ in }

		/**
		 Constructs a ButtonType object.

		 - parameter title: The title that will be displayed on the button.
		 - parameter style: The style that will be used for the button.
		 - parameter action: The action the alert should emit when this button is tapped. This closure is fed the text
		 of any textfields that might exist on the alert.
		 - parameter customize: This closure will be called on action construction to do any other customization
		 necessary.
		 */
		public init(title: String,
		            style: UIAlertAction.Style = .default,
		            action: @escaping ([String]) -> Action,
		            customize: @escaping (UIAlertAction) -> Void = { _ in })
		{
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
	func connect<Action>(buttons: [ButtonType<Action>] = [],
	                     fields: [(UITextField) -> Void] = []) -> Observable<Action>
	{
		Observable.create { [weak self] observer in
			let alertActions = buttons.map { button in
				let action = UIAlertAction(title: button.title, style: button.style) { _ in
					let texts = (self?.textFields ?? []).map { $0.text ?? "" }
					observer.onSuccess(button.action(texts))
				}
				button.customize(action)
				return action
			}
			for field in fields {
				self?.addTextField(configurationHandler: field)
			}
			for alertAction in alertActions {
				self?.addAction(alertAction)
			}
			return Disposables.create()
		}
	}
}
