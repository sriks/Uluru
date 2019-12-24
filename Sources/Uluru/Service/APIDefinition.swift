//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

public extension HTTPMethod {
    var name: String { return self.rawValue.uppercased() }
}

public enum EncodingStrategy {
    case ignore
    case queryParameters(parameters: JSONRepresentable)
    case jsonBody(parameters: JSONRepresentable)
    case jsonBodyUsingCustomEncoder(parameters: JSONRepresentable, encoder: JSONEncoder)
}

public protocol APIDefinition {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var encoding: EncodingStrategy { get }
    var headers: [String: String]? { get }
    var placeholderData: Data? { get }
}

extension APIDefinition {
    var placeholderData: Data? { return nil }
}

