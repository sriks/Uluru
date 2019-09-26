//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public extension ServiceRequester {

    static func defaultAPITargetResolver() -> APITargetResolver {
        let resolver: APITargetResolver = { apiDef in
            let target = APITarget.makeFrom(apiDef, resolvedURL: URL(api: apiDef))
            return .success(target)
        }
        return resolver
    }

    static func defaultRequestMapper() -> RequestMapper {
        let mapper: RequestMapper = { resolvedAPIDefinition in
            do {
                let urlRequest = try resolvedAPIDefinition.urlRequest()
                return .success(urlRequest)
            } catch {
                guard let serviceError = error as? ServiceError else {
                    return .failure(.requestMapping(resolvedAPIDefinition))
                }
                return .failure(serviceError)
            }
        }
        return mapper
    }

}

public extension URL {
    init<API: APIDefinition>(api: API) {
        if api.path.isEmpty {
            self = api.baseURL
        } else {
            self = api.baseURL.appendingPathComponent(api.path)
        }
    }
}


public extension ServiceRequester {
    // Essentially a pass through parser using vanilla JSONEncoder. 
    static func defaultParser() -> ResponseParser.Type {
        return DefaultJSONDecoder.self
    }
}

public extension ServiceRequester {
    static func defaultCompletionStrategyProvider() -> RequestCompletionStrategyProvidable {
        return DefaultContinueDecisionMaker()
    }
}

extension APITarget {
    func urlRequest() throws -> URLRequest {
        var ourRequest = URLRequest(url: url)
        try ourRequest.encoded(encoding)
        ourRequest.httpMethod = method.methodName

        // Firstly apply supplied headers
        if let suppliedHeaders = headers {
            suppliedHeaders.forEach { key, value in
                ourRequest.addValue(value, forHTTPHeaderField: key)
            }
        }

        // Then apply expected json header
        if encoding.expectsApplicationJSONHeader, headers?["Content-Type"] == nil {
            ourRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
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

public class DefaultJSONDecoder: ResponseParser {
    public static func make() -> ResponseParser {
        return DefaultJSONDecoder()
    }

    public func parse<T: Decodable>(_ response: DataResponse) -> Result<T, ParsingError> {
        do {
            let decoded: T = try JSONDecoder().decode(T.self, from: response.data)
            return .success(decoded)
        } catch {
            return .failure(.parsing(error))
        }
    }
}

public class DefaultContinueDecisionMaker: RequestCompletionStrategyProvidable {
    public func shouldFinish(_ result: DataResult, api: APIDefinition, decision: @escaping ShouldFinishDecision) {
        decision(.goahead)
    }
}
