//
//  Resource.swift
//
//  Created by Daniel Tartaglia on 19 May 2022.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import RxSwift

public final class Resource<Asset>: Disposable {
	public static func build(
		_ asset: @autoclosure @escaping () throws -> Asset,
		dispose: @escaping (Asset) -> Void
	) -> () throws -> Resource<Asset> {
		{ Resource(asset: try asset(), dispose: dispose) }
	}

	public static func createObservable<Action>(
		_ fn: @escaping (DisposeBag, Asset) -> Observable<Action>
	) -> (Resource<Asset>) -> Observable<Action> {
		{ resource in
			guard let asset = resource.asset else { return .empty() }
			return fn(resource.disposeBag, asset)
		}
	}

	private let asset: Asset?
	private let _dispose: (Asset) -> Void
	private let disposeBag = DisposeBag()

	init(asset: Asset?, dispose: @escaping (Asset) -> Void) {
		self.asset = asset
		self._dispose = dispose
	}

	public func dispose() {
		guard let asset = asset else { return }
		_dispose(asset)
	}
}

extension Resource where Asset: Disposable {
	public static func build(
		_ asset: @autoclosure @escaping () throws -> Asset
	) -> () throws -> Resource<Asset> {
		{ Resource(asset: try asset(), dispose: { $0.dispose() }) }
	}
}
