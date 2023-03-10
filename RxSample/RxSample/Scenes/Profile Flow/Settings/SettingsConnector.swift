//
//  SettingsConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import UIKit
import RxSwift
import RxCocoa

extension SettingsViewController {
	func connect() -> Observable<Void> {

		user
			.map { $0.map { "Logout \($0.username)" } ?? "Logout ..." }
			.bind(to: accountCell.textLabel!.rx.text)
			.disposed(by: disposeBag)

		let dismissed = SettingsLogic.dismiss(selected: tableView.rx.itemSelected.asObservable())
			.flatMapFirst { [unowned self] in
				self.rx.dismissSelf(animated: false)
			}

		return dismissed
			.take(1)
			.take(until: rx.deallocating)
			.take(until: doneButtonItem.rx.tap)
	}
}
