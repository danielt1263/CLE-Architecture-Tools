//
//  CLGeocoder+Rx.swift
//
//  Created by Daniel Tartaglia on 07 May 2016.
//  Copyright © 2023 Daniel Tartaglia. MIT License.
//

import RxSwift
import CoreLocation
import Contacts

public extension Reactive where Base: CLGeocoder {

	func reverseGeocodeLocation(_ location: CLLocation) -> Observable<[CLPlacemark]> {
		.create { observer in
			geocodeHandler(
				observer: observer,
				geocode: curry(self.base.reverseGeocodeLocation(_: completionHandler:), location)
			)
			return Disposables.create(with: dispose(self.base))
		}
		.subscribe(on: scheduler)
	}

	@available(iOS, introduced: 5.0, deprecated: 11.0, message: "Use -geocodePostalAddress:")
	func geocodeAddressDictionary(_ addressDictionary: [NSObject : AnyObject]) -> Observable<[CLPlacemark]> {
		.create { observer in
			geocodeHandler(
				observer: observer,
				geocode: curry(self.base.geocodeAddressDictionary(_: completionHandler:), addressDictionary)
			)
			return Disposables.create(with: dispose(self.base))
		}
		.subscribe(on: scheduler)
	}

	@available(iOS 11.0, *)
	func geocodePostalAddress(_ postalAddress: CNPostalAddress) -> Observable<[CLPlacemark]> {
		.create { observer in
			geocodeHandler(
				observer: observer,
				geocode: curry(self.base.geocodePostalAddress(_: completionHandler:), postalAddress)
			)
			return Disposables.create(with: dispose(self.base))
		}
		.subscribe(on: scheduler)
	}

	func geocodeAddressString(_ addressString: String) -> Observable<[CLPlacemark]> {
		.create { observer in
			geocodeHandler(
				observer: observer,
				geocode: curry(self.base.geocodeAddressString(_: completionHandler:), addressString)
			)
			return Disposables.create(with: dispose(self.base))
		}
		.subscribe(on: scheduler)
	}

	func geocodeAddressString(_ addressString: String, in region: CLRegion?) -> Observable<[CLPlacemark]> {
		.create { observer in
			geocodeHandler(
				observer: observer,
				geocode: curry(self.base.geocodeAddressString(_: in: completionHandler:), addressString, region)
			)
			return Disposables.create(with: dispose(self.base))
		}
		.subscribe(on: scheduler)
	}
}

private let semaphore = DispatchSemaphore(value: 1)
private let scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "CLGeocoderRx")

private func curry<A, B, C>(_ f: @escaping (A, B) -> C, _ a: A) -> (B) -> C {
	{ b in f(a, b) }
}

private func curry<A, B, C, D>(_ f: @escaping (A, B, C) -> D, _ a: A, _ b: B) -> (C) -> D {
	{ c in f(a, b, c) }
}

private func geocodeHandler(observer: AnyObserver<[CLPlacemark]>, geocode: @escaping (@escaping CLGeocodeCompletionHandler) -> Void) {
	semaphore.wait()
	geocode { placemarks, error in
		if let placemarks = placemarks {
			observer.onNext(placemarks)
			observer.onCompleted()
		} else {
			observer.onError(error ?? RxError.unknown)
		}
	}
}

private func dispose(_ geocoder: CLGeocoder) -> () -> Void {
	{
		geocoder.cancelGeocode()
		semaphore.signal()
	}
}
