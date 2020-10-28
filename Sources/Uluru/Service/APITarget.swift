// Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// A concrete resolved representation of an abstract `APIDefinition`. This representation can be used to a target to create a URLRequest.
public struct APITarget {
    // The fully resolved url
    public let url: URL

    public let path: String

    public let method: HTTPMethod

    public let encoding: EncodingStrategy

    public var headers: [String : String]?

    public init(url: URL, path: String, method: HTTPMethod, encoding: EncodingStrategy, headers: [String : String]?) {
        self.url = url
        self.path = path
        self.method = method
        self.encoding = encoding
        self.headers = headers
    }
}

public extension APITarget {

    /// Handy make to create an APITarget from a resolved URL and APIDefinition.
    ///
    /// - Parameters:
    ///   - apiDefinition: The pass through APIDefinition.
    ///   - resolvedURL: A resolved URL.
    static func makeFrom(_ apiDefinition: APIDefinition, resolvedURL: URL) -> APITarget {
        return .init(url: resolvedURL,
                     path: apiDefinition.path,
                     method: apiDefinition.method,
                     encoding: apiDefinition.encoding,
                     headers: apiDefinition.headers)
    }
}

public extension APITarget {
    mutating func add(httpHeader key: String, value: String) {
        var ourHeaders = headers ?? [:]
        ourHeaders[key] = value
        headers = ourHeaders
    }
}
