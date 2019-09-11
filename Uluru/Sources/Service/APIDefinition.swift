//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public enum TargetMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

public extension TargetMethod {
    var methodName: String { return self.rawValue.uppercased() }
}

public typealias JSON = [String: Any]

/// Provides a JSON representation.
public protocol JSONRepresentable {
    func jsonObject() throws -> JSON
    func jsonData(using encoder: JSONEncoder) throws -> Data
}

extension JSONRepresentable {
    func jsonData() throws -> Data {
        return try self.jsonData(using: JSONEncoder())
    }
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
    var method: TargetMethod { get }
    var encoding: EncodingStrategy { get }
    var headers: [String: String]? { get }
    var placeholderData: Data? { get }
}

extension APIDefinition {
    var placeholderData: Data? { return nil }
}

