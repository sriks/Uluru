//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

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
