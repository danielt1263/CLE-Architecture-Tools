//
//  ProfileViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//   Copyright © 2022 Daniel Tartaglia. MIT License.
//

import UIKit
import RxSwift

final class ProfileViewController: UIViewController {

	@IBOutlet weak var settingsButtonItem: UIBarButtonItem!
	@IBOutlet weak var avatarView: UIView! {
		didSet {
			avatarView.layer.cornerRadius = 35
		}
	}
	@IBOutlet weak var avatarLabel: UILabel!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var usernameLabel: UILabel!

	let disposeBag = DisposeBag()
}
