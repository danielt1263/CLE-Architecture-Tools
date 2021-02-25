//
//  SettingsViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//	Copyright © 2020 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

final class SettingsViewController: UITableViewController {

	@IBOutlet weak var doneButtonItem: UIBarButtonItem!
	@IBOutlet weak var accountCell: UITableViewCell!

	let disposeBag = DisposeBag()
}
