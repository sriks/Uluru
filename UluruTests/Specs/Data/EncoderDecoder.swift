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
    static func make<API>(_ api: API) -> ResponseParser where API : APIDefinition {
        return CustomParser()
    }

    static var isInvoked = false

    func parse<T>(_ response: DataResponse) -> Result<T, ParsingError> where T : Decodable {
        CustomParser.isInvoked = true
        do {
            let parsed = try JSONDecoder().decode(T.self, from: response.data)
            return .success(parsed)
        } catch {
            return .failure(.parsing(error))
        }
    }
}
