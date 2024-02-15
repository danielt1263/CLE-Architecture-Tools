//
//  CancelableEffectTests.swift
//
//
//  Created by Daniel Tartaglia on 15 Feb 2024.
//  Copyright © 2024 Daniel Tartaglia. MIT License.
//

import Cause_Logic_Effect
import RxSwift
import RxTest
import Test_Tools
import XCTest

final class CancelableEffectTests: XCTestCase {
    func testNormalEffect() {
        let scheduler = TestScheduler(initialClock: 0)
        let effect = parseTimeline("--A|")
        let source = scheduler.createObservable(effect)
        let result = scheduler.start {
            source
                .cancelable(id: "test")
        }
        XCTAssertEqual(result.events, effect.offsetTime(by: 200)[0])
    }

    func testCancelsUnfinishedCancelable() {
        let scheduler = TestScheduler(initialClock: 0)
        let effect = parseTimeline("---A|")
        let source = scheduler.createObservable(effect)
        let observer = scheduler.createObserver(String.self)

        _ = source
            .cancelable(id: "test")
            .subscribe(observer)

        scheduler.scheduleAt(2) {
            _ = Observable<Never>.cancel(id: "test")
                .subscribe()
        }

        scheduler.start()

        XCTAssertEqual(observer.events, [])
    }

    func testNormalCancelablesDoNotInterfearWithEachOther() {
        let scheduler = TestScheduler(initialClock: 0)
        let effect = parseTimeline("---A|")
        let source = scheduler.createObservable(effect)
        let observer = scheduler.createObserver(String.self)
        let observer1 = scheduler.createObserver(String.self)

        _ = source
            .cancelable(id: "test")
            .subscribe(observer)

        scheduler.scheduleAt(2) {
            _ = source
                .cancelable(id: "test")
                .subscribe(observer1)
        }

        scheduler.start()

        XCTAssertEqual(observer.events, effect[0])
        XCTAssertEqual(observer1.events, effect.offsetTime(by: 2)[0])
    }

    func testSubsequentCancelablesWithSameIDCanCancelPreviousOnes() {
        let scheduler = TestScheduler(initialClock: 0)
        let effect = parseTimeline("---A|")
        let source = scheduler.createObservable(effect)
        let observer = scheduler.createObserver(String.self)
        let observer1 = scheduler.createObserver(String.self)

        _ = source
            .cancelable(id: "test")
            .subscribe(observer)

        scheduler.scheduleAt(2) {
            _ = source
                .cancelable(id: "test", cancelInFlight: true)
                .subscribe(observer1)
        }

        scheduler.start()

        XCTAssertEqual(observer.events, [])
        XCTAssertEqual(observer1.events, effect.offsetTime(by: 2)[0])
    }
}
