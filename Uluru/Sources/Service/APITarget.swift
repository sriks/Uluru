// Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// A concrete resolved representation of an abstract `APIDefinition`. This representation can be used to a target to create a URLRequest.
public struct APITarget {
    // The fully resolved url
    public let url: URL

    public let path: String

    public let method: TargetMethod

    public let encoding: EncodingStrategy

    public var headers: [String : String]?
}

extension APITarget {
    mutating func add(httpHeader key: String, value: String) {
        var ourHeaders = headers ?? [:]
        ourHeaders[key] = value
        headers = ourHeaders
    }
}

