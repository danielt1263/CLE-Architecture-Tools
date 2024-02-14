//
//  SettingsViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

final class SettingsViewController: UITableViewController {
	@IBOutlet var doneButtonItem: UIBarButtonItem!
	@IBOutlet var accountCell: UITableViewCell!

	let disposeBag = DisposeBag()
}
