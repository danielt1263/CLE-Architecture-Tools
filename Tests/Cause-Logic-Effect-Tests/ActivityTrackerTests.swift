//
//  ActivityTrackerTests.swift
//  
//
//  Created by Daniel Tartaglia on 10/14/23.
//

import Cause_Logic_Effect
import Test_Tools
import RxTest
import XCTest

final class ActivityTrackerTests: XCTestCase {
    func test() {
        let scheduler = TestScheduler(initialClock: 0)
        let source = scheduler.createObservable(timeline: "--A|")
        let expected = parseEventsAndTimes(timeline:     "FT-F", values: { $0 == "T" })
        let result = scheduler.createObserver(Bool.self)
        let activityTracker = ActivityTracker()

        _ = activityTracker.isActive
            .subscribe(result)

        _ = scheduler.scheduleRelative((), dueTime: .seconds(1)) {
            source
                .trackActivity(activityTracker)
                .subscribe()
        }

        scheduler.start()
        XCTAssertEqual(result.events, expected[0])
    }

    func test1() {
        let scheduler = TestScheduler(initialClock: 0)
        let source = scheduler.createObservable(timeline:  "--A|")
        let expected = parseEventsAndTimes(timeline:      "FT---F", values: { $0 == "T" })
        let result = scheduler.createObserver(Bool.self)
        let activityTracker = ActivityTracker()

        _ = activityTracker.isActive
            .subscribe(result)

        _ = scheduler.scheduleRelative((), dueTime: .seconds(1)) {
            source
                .trackActivity(activityTracker)
                .subscribe()
        }

        _ = scheduler.scheduleRelative((), dueTime: .seconds(3)) {
            source
                .trackActivity(activityTracker)
                .subscribe()
        }

        scheduler.start()
        XCTAssertEqual(result.events, expected[0])
    }

    func test2() {
        let scheduler = TestScheduler(initialClock: 0)
        let source = scheduler.createObservable(timeline:  "--A|")
        let expected = parseEventsAndTimes(timeline:      "FT-FT-F", values: { $0 == "T" })
        let result = scheduler.createObserver(Bool.self)
        let activityTracker = ActivityTracker()

        _ = activityTracker.isActive
            .subscribe(result)

        _ = scheduler.scheduleRelative((), dueTime: .seconds(1)) {
            source
                .trackActivity(activityTracker)
                .subscribe()
        }

        _ = scheduler.scheduleRelative((), dueTime: .seconds(4)) {
            source
                .trackActivity(activityTracker)
                .subscribe()
        }

        scheduler.start()
        XCTAssertEqual(result.events, expected[0])
    }
}

