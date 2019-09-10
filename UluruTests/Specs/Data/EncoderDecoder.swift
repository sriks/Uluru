//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
@testable import Uluru

// A fake encoder to ensure it is invoked.
class CustomEncoder: JSONEncoder {
    var isInvoked = false

    override func encode<T>(_ value: T) throws -> Data where T : Encodable {
        isInvoked = true
        return try JSONEncoder().encode(value)
    }
}

// A fake decoder to ensure it is invoked.
class CustomDecoder: JSONDecoder {
    var isInvoked = false

    override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        isInvoked = true
        return try JSONDecoder().decode(type, from: data)
    }
}

class CustomParser: ResponseParser {
    static var isInvoked = false
    static func make() -> ResponseParser {
        return CustomParser()
    }

    func parse<T>(_ response: DataSuccessResponse) throws -> Result<T, ServiceError> where T : Decodable {
        CustomParser.isInvoked = true
        do {
            let parsed = try JSONDecoder().decode(T.self, from: response.data)
            return .success(parsed)
        } catch {
            return .failure(.decodingFailed(response, error))
        }
    }
}

class CustomKeyedResponseParser: ResponseParser {
    static func make() -> ResponseParser {
        return CustomKeyedResponseParser()
    }

    func parse<T>(_ response: DataSuccessResponse) throws -> Result<T, ServiceError> where T : Decodable {

        if let json = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? JSON,
            let responseError = json["error"] as? JSON {
            return .failure(.responseError(response, responseError))
        }
        do {
            let decoder = JSONDecoder()
            let decoded: T = try decoder.decode(T.self, from: response.data)
            return .success(decoded)
        } catch {
            return .failure(.decodingFailed(response, error))
        }
    }
}
