//
//  AttachOperators.swift
//
//  Created by Daniel Tartaglia on 3 Oct 2022.
//  Copytright © 2022 Daniel Tartaglia. MIT License.
//

import RxCocoa
import RxSwift

infix operator <-: AssignmentPrecedence

func <- <O1, O2>(lhs: O1, rhs: O2) -> Disposable
where O1: ObserverType, O2: ObservableType, O1.Element == O2.Element {
	rhs.bind(to: lhs)
}

func <- <O1, O2>(lhs: O1, rhs: O2) -> Disposable
where O1: ObserverType, O2: ObservableType, O1.Element == O2.Element? {
	rhs.bind(to: lhs)
}

func <- <Obs, Result>(lhs: (Obs) -> Result, rhs: Obs) -> Result
where Obs: ObservableType {
	rhs.bind(to: lhs)
}

func <- <Element, Obs>(lhs: BehaviorRelay<Element>, rhs: Obs) -> Disposable
where Obs: ObservableType, Element == Obs.Element {
	rhs.bind(to: lhs)
}

func <- <Element, Obs>(lhs: PublishRelay<Element>, rhs: Obs) -> Disposable
where Obs: ObservableType, Element == Obs.Element {
	rhs.bind(to: lhs)
}
