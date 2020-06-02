//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

public extension HTTPMethod {
    var name: String { return self.rawValue.uppercased() }
}

/// The encoding strategy as per the http method.
public enum EncodingStrategy {
    /// Dont encode. Just send in plain.
    case dontEncode

    /// Encode as query parmeters
    case queryParameters(parameters: JSONRepresentable)

    /// Encode as JSON body paramaters
    case jsonBody(parameters: JSONRepresentable)

    /// Encode as JSON body paramaters using the supplied custom JSONEncoder
    case jsonBodyUsingCustomEncoder(parameters: JSONRepresentable, encoder: JSONEncoder)
}

/// Represents **what** an API request to an endpoint is.
public protocol APIDefinition {

    /// Base url of the API service
    /// - Example
    /// ```swift
    /// return URL(string: "https://jsonplaceholder.typicode.com")!
    /// ```
    var baseURL: URL { get }

    /// The URI path
    /// * For example "/comments".
    /// * Observe the prefix "/"
    var path: String { get }

    /// The HTTP method
    var method: HTTPMethod { get }

    /// The encoding strategy as per the HTTPMethod.
    var encoding: EncodingStrategy { get }

    /// The HTTP headers
    var headers: [String: String]? { get }

    /// A place holder data.
    /// * If you provide one, it is used instead of making an API call.
    /// * Should be used when testing APIs offline.
    /// * You are responsible to remove it in production code.
    var placeholderData: Data? { get }
}

extension APIDefinition {
    var placeholderData: Data? { return nil }
}

