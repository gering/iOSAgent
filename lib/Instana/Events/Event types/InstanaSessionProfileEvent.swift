//  Created by Nikola Lajic on 1/25/19.
//  Copyright © 2019 Nikola Lajic. All rights reserved.

import Foundation

class InstanaSessionProfileEvent: InstanaEvent, InstanaEventResultNotifiable {
    var completion: CompletionBlock {
        get { return handleCompletion }
    }
    private let maxRetryInterval = 30_000
    private var retryInterval = 50 {
        didSet {
            if retryInterval > maxRetryInterval { retryInterval = maxRetryInterval }
        }
    }
    
    init() {
        super.init(eventId: nil, timestamp: 0)
    }
    
    private override init(sessionId: String, eventId: String?, timestamp: Instana.Types.UTCTimestamp) {
        fatalError()
    }
    
    override func toJSON() -> [String : Any] {
        var json = super.toJSON()
        json["profile"] = [
            "platform": "iOS",
            "osDistro": "Apple",
            "osLevel": InstanaSystemUtils.systemVersion,
            "deviceType": InstanaSystemUtils.deviceModel,
            "appVersion": InstanaSystemUtils.applicationVersion,
            "appBuild": InstanaSystemUtils.applicationBuildNumber
        ]
        return json
    }
}

private extension InstanaSessionProfileEvent {
    func handleCompletion(result: InstanaEventResult) -> Void {
        switch result {
        case .success:
            Instana.log.add("Session profile sent")
        case .failure(_):
            Instana.log.add("Failed to send session profile. Retrying in \(retryInterval) ms.")
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(retryInterval)) {
                Instana.events.submit(event: self)
            }
            retryInterval *= 2
        }
    }
}
