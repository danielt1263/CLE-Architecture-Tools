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
		let choice = pickerView.rx.itemSelected.map { choices[$0.row] }
			.share(replay: 1)

		inputView = pickerView

		_ = Observable.using(
			{ [unowned self] in
				DelegateHolder(textField: self, delegate: OnlyListItemDelegate(items: choices.map(description)))
			},
			observableFactory: { $0.delegate!.index }
		)
		.take(until: rx.deallocating)
		.subscribe(onNext: { index in
			pickerView.selectRow(index, inComponent: 0, animated: true)
		})

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

private class DelegateHolder<T: UITextFieldDelegate>: Disposable {
	private (set) var delegate: T?

	init(textField: UITextField, delegate: T) {
		textField.delegate = delegate
		self.delegate = delegate
	}

	func dispose() {
		delegate = nil
	}
}

private class OnlyListItemDelegate: NSObject, UITextFieldDelegate {
	let items: [String]
	let index: Observable<Int>
	private let _index = PublishSubject<Int>()

	init(items: [String]) {
		self.items = items
		self.index = _index.asObservable()
	}

	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let currentText = textField.text ?? ""
		guard let stringRange = Range(range, in: currentText) else { return false }
		let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
		if let index = items.firstIndex(where: { $0.hasPrefix(updatedText) }) {
			_index.onNext(index)
			return true
		}
		else {
			return false
		}
	}
}
