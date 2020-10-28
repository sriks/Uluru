//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public typealias JSON = [String: Any]

/// Provides a JSON representation.
public protocol JSONRepresentable {
    func jsonObject(using encoder: JSONEncoder) throws -> JSON
    func jsonData(using encoder: JSONEncoder) throws -> Data
}

extension JSONRepresentable {
    func jsonObject() throws -> JSON {
        return try self.jsonObject(using: JSONEncoder())
    }

    func jsonData() throws -> Data {
        return try self.jsonData(using: JSONEncoder())
    }
}

// Default implementation for any type confirming to `Encodable`
public extension JSONRepresentable where Self: Encodable {
    func jsonObject(using encoder: JSONEncoder) throws -> JSON {
        guard let json = try JSONSerialization.jsonObject(with: self.jsonData(using: encoder),
                                                          options: .mutableContainers) as? JSON else {
            fatalError("Unable to represent to expected JSON type aka [String: Any]")
        }
        return json
    }

    func jsonData(using encoder: JSONEncoder) throws -> Data {
        return try encoder.encode(self)
    }
}
