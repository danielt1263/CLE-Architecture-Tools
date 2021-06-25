//
//  UTTextField+Picker.swift
//
//  Created by Daniel Tartaglia on 12/14/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

extension UITextField {
	func picker<T>(choices: [T], initial: T? = nil, description: @escaping (T) -> String = { String(describing: $0) }) -> Observable<T?> {
		let pickerView = UIPickerView()
		let fullChoices = [""] + choices.map(description)
		let choice = pickerView.rx.itemSelected.map { $0.row == 0 ? nil : choices[$0.row - 1] }
			.startWith(initial)
			.share(replay: 1)

		inputView = pickerView
		delegate = NoTextInputDelegate.instance

		_ = Observable.just(fullChoices)
			.bind(to: pickerView.rx.itemTitles) { _, element in
				return element
			}

		if let initial = initial {
			pickerView.reloadAllComponents()
			pickerView.selectRow((choices.firstIndex(where: { description($0) == description(initial) }) ?? -1) + 1, inComponent: 0, animated: false)
		}

		_ = choice
			.map { $0.map { description($0) } }
			.startWith(initial.map { description($0) })
			.bind(to: rx.text)

		return choice
	}
}

class NoTextInputDelegate: NSObject, UITextFieldDelegate {
	static let instance = NoTextInputDelegate()
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return false
	}
}
