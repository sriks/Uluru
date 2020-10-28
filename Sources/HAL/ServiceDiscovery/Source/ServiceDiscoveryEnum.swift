//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public enum DiscoveryError: Error {
    case discoveryIsUpToDate
    case urlLoadingFailed
    case parsingFailed
    case fileNotFound
}

extension DiscoveryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .discoveryIsUpToDate:
            return "Service Discovery refreshs too often"
        case .urlLoadingFailed:
            return "Service Discovery failed to load from server"
        case .parsingFailed:
            return "Failed to parsing data"
        case .fileNotFound:
            return "Can't find a file as expected"
        }
    }
}

extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}
