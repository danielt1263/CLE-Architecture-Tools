//
//  PhotoConnector.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//	Copyright © 2020 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxCocoa
import RxSwift
import UIKit

extension PhotoViewController {

	func connect(url: URL) -> Observable<Never> {
		let errorRouter = ErrorRouter()

		let photoRequest = URLSession.shared.rx.data(request: URLRequest(url: url))
			.rerouteError(errorRouter)

		photoRequest
			.map(to: true)
			.startWith(false)
			.bind(to: activityIndicatorView.rx.isHidden)
			.disposed(by: disposeBag)

		photoRequest
			.map { UIImage(data: $0) }
			.bind(to: imageView.rx.image)
			.disposed(by: disposeBag)

		errorRouter.error
			.map { $0.localizedDescription }
			.bind(onNext: presentScene(animated: true) { message in
				UIAlertController(title: "Error", message: message, preferredStyle: .alert).scene { $0.connectOK() }
			})
			.disposed(by: disposeBag)

		return Observable.never()
			.take(until: rx.deallocating)
	}
}
