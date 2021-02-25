//
//  SignupViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

final class SignupViewController: UIViewController {

	@IBOutlet weak var firstNameTextField: UITextField!
	@IBOutlet weak var lastNameTextField: UITextField!
	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var signupButton: UIButton!
	@IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

	let disposeBag = DisposeBag()
}
