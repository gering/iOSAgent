//  Created by Nikola Lajic on 12/26/18.
//  Copyright © 2018 Nikola Lajic. All rights reserved.

import Foundation

class Monitors {

    var applicationNotResponding: ApplicationNotRespondingMonitor?
    var lowMemory: LowMemoryMonitor?
    var framerateDrop: FramerateDropMonitor?
    var http: HTTPMonitor?
    lazy var network = NetworkMonitor()
    private let configuration: InstanaConfiguration
    let reporter: Reporter

    init(_ configuration: InstanaConfiguration) {
        self.configuration = configuration
        self.reporter = Reporter(configuration)
        configuration.monitorTypes.forEach { type in
            switch type {
            case .http:
                http = HTTPMonitor(configuration, reporter: reporter)
            case .memoryWarning:
                lowMemory = LowMemoryMonitor(reporter: reporter)
            case .framerateDrop(let threshold):
                framerateDrop = FramerateDropMonitor(threshold: threshold, reporter: reporter)
            case .alertApplicationNotResponding(let threshold):
                applicationNotResponding = ApplicationNotRespondingMonitor(threshold: threshold, reporter: reporter)
            }
        }

        network.connectionUpdateHandler = {[weak self] connectionType in
            guard let self = self else { return }
            if connectionType != .none {
                self.reporter.flushQueue()
            }
        }
    }
}
