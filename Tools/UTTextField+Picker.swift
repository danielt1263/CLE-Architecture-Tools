//
//  UTTextField+Picker.swift
//
//  Created by Daniel Tartaglia on 12/14/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

extension UITextField {
	func picker<T>(choices: [T], initial: T? = nil, description: @escaping (T) -> String = { String(describing: $0) }) -> Observable<T> {
		let pickerView = UIPickerView()
		let choice = Observable.merge(
			rx.controlEvent(.editingDidBegin).take(1).map { initial ?? choices[0] },
			pickerView.rx.itemSelected.map { choices[$0.row] }
		)
		.share(replay: 1)

		inputView = pickerView
		delegate = NoTextInputDelegate.instance

		_ = Observable.just(choices.map(description))
			.bind(to: pickerView.rx.itemTitles) { _, element in
				return element
			}

		if let initial = initial {
			pickerView.reloadAllComponents()
			pickerView.selectRow(choices.firstIndex(where: { description($0) == description(initial) }) ?? 0, inComponent: 0, animated: false)
		}

		_ = choice
			.map(description)
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
