//
//  DatePickerSetup.swift
//
//  Created by Daniel Tartaglia on 10/2/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

enum DateEntryMode {
	case date
	case time
	case dateAndTime
}

func setUpDatePicker(on view: UIView, tint: UIColor, entryMode: DateEntryMode, initial: Date? = nil) -> Observable<Date> {
	let picker = UIDatePicker()
	setUpDatePicker(picker, on: view, tint: tint, entryMode: entryMode, initial: initial)
	return picker.rx.date.asObservable()
}

func setUpDatePicker(_ picker: UIDatePicker, on view: UIView, tint: UIColor, entryMode: DateEntryMode, initial: Date?) {
	switch entryMode {
	case .date:
		picker.datePickerMode = .date
	case .time:
		picker.datePickerMode = .time
	case .dateAndTime:
		picker.datePickerMode = .dateAndTime
	}
	picker.date = initial ?? Date()

	if #available(iOS 13.4, *) {
		picker.tintColor = tint
		picker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		picker.frame = view.bounds.intersection(picker.frame)
		view.addSubview(picker)
	}
	else {
		let textField = UITextField(frame: view.bounds)
		textField.textColor = tint
		textField.inputView = picker
		textField.delegate = NoTextDelegate.instance
		textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.addSubview(textField)

		let formatter = DateFormatter()
		switch entryMode {
		case .date:
			formatter.dateStyle = 114 < view.bounds.width ? .medium : .short
		case .time:
			formatter.dateStyle = .none
		case .dateAndTime:
			formatter.dateStyle = 204 < view.bounds.width ? .medium : .short
		}
		formatter.timeStyle = entryMode == .date ? .none : .short

		_ = picker.rx.date
			.map { formatter.string(from: $0) }
			.take(until: textField.rx.deallocating)
			.bind(to: textField.rx.text)
	}
}

private final class NoTextDelegate: NSObject, UITextFieldDelegate {
	static let instance = NoTextDelegate()
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return false
	}
}
