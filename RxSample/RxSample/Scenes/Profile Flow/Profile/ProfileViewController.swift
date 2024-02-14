//
//  ProfileViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

final class ProfileViewController: UIViewController {
	@IBOutlet var settingsButtonItem: UIBarButtonItem!
	@IBOutlet var avatarView: UIView! {
		didSet {
			avatarView.layer.cornerRadius = 35
		}
	}

	@IBOutlet var avatarLabel: UILabel!
	@IBOutlet var nameLabel: UILabel!
	@IBOutlet var usernameLabel: UILabel!

	let disposeBag = DisposeBag()
}
