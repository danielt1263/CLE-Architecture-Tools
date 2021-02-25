//
//  AppDelegate.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/11/20.
//  Copyright © 2020 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxSwift
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		let controller = UISplitViewController()
				.configure { $0.connect() }
		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = controller
		window?.makeKeyAndVisible()

		_ = user
			.filter { $0 == nil }
			.map(to: ())
			.bind(onNext: presentScene(animated: true, scene: loginNavigation))

		_ = errorRouter.error
			.map { $0.localizedDescription }
			.bind(
				onNext: presentScene(animated: true) { message in
					UIAlertController(title: "Error", message: message, preferredStyle: .alert).scene { $0.connectOK() }
				}
			)

		#if DEBUG
		_ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
			.map(to: ())
			.flatMap { Observable.just(RxSwift.Resources.total) }
			.distinctUntilChanged()
			.subscribe(onNext: { print("♦️ Resource count \($0)") })
		#endif

		return true
	}
}
