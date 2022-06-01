//
//  PostsLogic.swift
//  RxSample
//
//  Created by Daniel Tartaglia on 6/13/20.
//  Copyright © 2022 Daniel Tartaglia. MIT License.
//

import Foundation
import RxSwift

enum PostsLogic {

	static func getPosts(trigger: Observable<Void>, user: Observable<User?>) -> Observable<User.ID> {
		Observable.combineLatest(trigger.startWith(()), user)
			.compactMap { $0.1?.id }
	}

}
