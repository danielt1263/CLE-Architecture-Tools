//
//  UITextField+WheeledDatePicker.swift
//
//  Created by Daniel Tartaglia on 9/9/21.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift
import UIKit

enum DateEntryMode {
	case date
	case time
	case dateAndTime
}

extension UITextField {
	func wheeledDatePicker(entryMode: DateEntryMode, initial: Date? = nil) -> UIDatePicker {
		let picker = UIDatePicker()
		switch entryMode {
		case .date:
			picker.datePickerMode = .date
		case .time:
			picker.datePickerMode = .time
		case .dateAndTime:
			picker.datePickerMode = .dateAndTime
		}
		if #available(iOS 13.4, *) {
			picker.preferredDatePickerStyle = .wheels
		}

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
			.take(until: rx.deallocating)
			.bind(to: rx.text)
		return picker
	}
}

private final class NoTextDelegate: NSObject, UITextFieldDelegate {
	static let instance = NoTextDelegate()
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return false
	}
}
