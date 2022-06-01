//
//  LoginViewController.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 11/14/20.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import RxSwift
import UIKit

final class LoginViewController: UIViewController {

	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var loginButton: UIButton!
	@IBOutlet weak var signupButton: UIButton!
	@IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
	
	let disposeBag = DisposeBag()
}
