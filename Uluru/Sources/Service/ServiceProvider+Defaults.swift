//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public extension ServiceProvider {

    static var defaultAPIDefinitionResolver: APIDefinitionResolver {
        let resolver: APIDefinitionResolver = { apiDef in
            // TODO: use extension on URL to cleanly create this.
            return ResolvedAPIDefinition(url: apiDef.baseURL.appendingPathComponent(apiDef.path),
                                         path: apiDef.path,
                                         method: apiDef.method,
                                         encoding: apiDef.encoding,
                                         headers: apiDef.headers,
                                         authorizationType: apiDef.authorizationType)

        }
        return resolver
    }

    static func defaultRequestMapper() -> RequestMapper {
        let mapper: RequestMapper = { resolvedAPIDefinition in
            do {
                let urlRequest = try resolvedAPIDefinition.urlRequest()
                return .success(urlRequest)
            } catch {
                return .failure(error)
            }
        }
        return mapper
    }
}

extension ResolvedAPIDefinition {
    func urlRequest() throws -> URLRequest {
        var ourRequest = URLRequest(url: url)
        try ourRequest.encoded(encoding)
        ourRequest.applyingHTTPMethod(method.methodName)

        // Firstly apply supplied headers
        if let suppliedHeaders = headers {
            suppliedHeaders.forEach { key, value in
                ourRequest.adding(value: value, headerField: key)
            }
        }

        // Then apply expected json header
        if encoding.expectsApplicationJSONHeader, headers?["Content-Type"] == nil {
            ourRequest.adding(value: "application/json", headerField: "Content-Type")
        }
        return ourRequest
    }
}

// MARK: - Encodable
// Default implementation for any type confirming to `Encodable`
public extension JSONRepresentable where Self: Encodable {
    func jsonObject() throws -> JSON {
        guard let json = try JSONSerialization.jsonObject(with: self.jsonData(), options: .mutableContainers) as? JSON else {
            fatalError("Unable to represent to expected JSON type aka [String: Any]")
        }
        return json
    }

    func jsonData(using encoder: JSONEncoder) throws -> Data {
        return try encoder.encode(self)
    }
}

