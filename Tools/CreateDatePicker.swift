//
//  DatePickerSetup.swift
//
//  Created by Daniel Tartaglia on 10/2/20.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

enum DateEntryMode {
	case date
	case time
	case dateAndTime
}

func createDatePicker(on view: UIView, tint: UIColor, entryMode: DateEntryMode, initial: Date?) -> UIDatePicker {
	let picker = UIDatePicker()
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
		formatter.dateStyle = entryMode == .time ? .none : .medium
		formatter.timeStyle = entryMode == .date ? .none : .short

		let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: bounds.height)
		let boundingBox = formatter.string(from: Date()).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font!], context: nil)
		let textWidth = ceil(boundingBox.width)

		if textWidth + 14 > bounds.width && entryMode != .time {
			formatter.dateStyle = .short
		}

		_ = picker.rx.date
			.map { formatter.string(from: $0) }
			.take(until: textField.rx.deallocating)
			.bind(to: textField.rx.text)
	}
	return picker
}

private final class NoTextDelegate: NSObject, UITextFieldDelegate {
	static let instance = NoTextDelegate()
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return false
	}
}
