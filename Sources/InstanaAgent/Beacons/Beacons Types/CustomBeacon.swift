//
//  File.swift
//
//
//  Created by Christian Menschel on 07.05.20.
//

import Foundation

class CustomBeacon: Beacon {
    let name: String
    let duration: Instana.Types.Milliseconds?
    let backendTracingID: String?
    let error: Error?
    let meta: [String: String]?

    init(timestamp: Instana.Types.Milliseconds = Date().millisecondsSince1970,
         name: String,
         duration: Instana.Types.Milliseconds? = nil,
         backendTracingID: String? = nil,
         error: Error? = nil,
         meta: [String: String]? = nil,
         viewName: String? = nil) {
        self.duration = duration
        self.name = name
        self.error = error
        self.meta = meta
        self.backendTracingID = backendTracingID
        super.init(timestamp: timestamp, viewName: viewName)
    }
}
