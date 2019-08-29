//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public struct ResolvedAPIDefinition {
    // The fully resolved url
    public let url: URL

    public let path: String

    public let method: TargetMethod

    public let encoding: EncodingStrategy

    public var headers: [String : String]?

    public let authorizationType: TypeOfAuthorization
}

extension ResolvedAPIDefinition {
    mutating func add(httpHeader key: String, value: String) {
        var ourHeaders = headers ?? [:]
        ourHeaders[key] = value
        headers = ourHeaders
    }
}

