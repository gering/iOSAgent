//  Created by Nikola Lajic on 2/28/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import XCTest
@testable import InstanaSensor

class ApplicationNotRespondingMonitorTests: XCTestCase {

    var monitor: ApplicationNotRespondingMonitor?
    var instana: Instana!

    override func setUp() {
        super.setUp()
        Instana.setup(key: "KEY")
        self.instana = Instana.current
    }

    override func tearDown() {
        instana = nil
        monitor = nil
    }
    
    func test_internalTimer_shouldNotRetainMonitor() {
        monitor = ApplicationNotRespondingMonitor(threshold: 5, reporter: MockReporter {_ in })
        weak var weakMonitor = monitor
        
        monitor = nil
        
        XCTAssertNil(weakMonitor)
    }
    
    func test_performanceOverload_triggersANRBeacon() {
        var beacon: Beacon?
        let exp = expectation(description: "ANR beacon trigger")
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1, reporter: MockReporter {
            beacon = $0
            exp.fulfill()
        })
        
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14) { _ in
            guard let alert = beacon as? AlertBeacon else {
                XCTFail("Beacon not submitted or wrong type")
                return
            }
            guard case let .anr(duration) = alert.alertType else {
                XCTFail("Wrong alert type: \(alert.alertType)")
                return
            }
            XCTAssert(duration > 0.01)
        }
    }
    
    func test_backgroundedApplication_shouldNotTriggerANRBeacon() {
        let exp = expectation(description: "ANR beacon trigger")
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1, reporter: MockReporter {_ in
            XCTFail("ANR beacon triggered in background")
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(120)) {
            exp.fulfill()
        }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14)
    }
    
    func test_foregrounding_shouldResumeMonitoring() {
        var beacon: Beacon?
        var count = 0
        let exp = expectation(description: "ANR beacon trigger")
        monitor = ApplicationNotRespondingMonitor(threshold: 0.01, samplingInterval: 0.1, reporter: MockReporter {
            beacon = $0
            count += 1
        })
        // fulfill expectation after a timer to catch mutliple beacons
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(120)) {
            exp.fulfill()
        }
        
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        Thread.sleep(forTimeInterval: 0.12)
        
        waitForExpectations(timeout: 0.14) { _ in
            XCTAssertNotNil(beacon as? AlertBeacon)
            XCTAssertEqual(count, 1)
        }
    }
}
