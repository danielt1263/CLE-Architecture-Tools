//
//  UITextField+WheeledDatePicker.swift
//
//  Created by Daniel Tartaglia on 9/9/21.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift
import UIKit

extension UITextField {
	func wheeledDatePicker(initial: Date? = nil, formatter: DateFormatter, pickerFormatter: (UIDatePicker) -> Void) -> Observable<Date> {
		let pickerView = UIDatePicker()
		pickerFormatter(pickerView)
		pickerView.preferredDatePickerStyle = .wheels
		let choice = Observable.merge(
			rx.controlEvent(.editingDidBegin).take(1).map { initial ?? Date() },
			pickerView.rx.date.skip(1)
		)
		.share(replay: 1)

		inputView = pickerView
		delegate = NoTextDelegate.instance

		_ = choice
			.map { Optional.some($0) }
			.startWith(initial)
			.compactMap { $0.map { formatter.string(from: $0) } ?? nil }
			.bind(to: rx.text)

		return choice
	}
}

private final class NoTextDelegate: NSObject, UITextFieldDelegate {
	static let instance = NoTextDelegate()
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return false
	}
}
