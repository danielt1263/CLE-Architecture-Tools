//___FILEHEADER___

import RxCocoa
import RxSwift
import UIKit

extension ___VARIABLE_productName___ViewController {
	func connect() -> Observable<___VARIABLE_productName___Action> {

		// connect views here.

		// return action to communicate to parent view controller.
		let action = Observable<___VARIABLE_productName___Action>.never()
			.take(until: rx.deallocating)

		return action
	}
}

enum ___VARIABLE_productName___Action {

}
