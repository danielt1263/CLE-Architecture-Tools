//
//  LoginViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

final class LoginViewController: UIViewController {
	@IBOutlet var emailTextField: UITextField!
	@IBOutlet var passwordTextField: UITextField!
	@IBOutlet var loginButton: UIButton!
	@IBOutlet var signupButton: UIButton!
	@IBOutlet var activityIndicatorView: UIActivityIndicatorView!

	let disposeBag = DisposeBag()
}
