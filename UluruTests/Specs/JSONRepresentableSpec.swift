import Foundation
import Quick
import Nimble
@testable import Uluru

class JSONRepresentableSpec: QuickSpec {
    let aModel = SampleModel(name: "Godzilla", age: 100, extinct: true)

    override func spec() {
        describe("JSONRepresentable and conforming to Encodable") {
            context("when using default Encoder") {
                let json = try! aModel.jsonObject()

                it("should convert to json object") {
                    expect(self.testExpectation(json)).to( beTrue() )
                }
            }

            context("when using custom encoder") {
                let customEncoder = MyJSONEncoder()
                let json = try! aModel.jsonObject(using: customEncoder)

                it("should use the provided encoder") {
                    expect(customEncoder.isInvoked).to( beTrue() )
                }

                it("should convert to json object") {
                    expect(self.testExpectation(json)).to( beTrue() )
                }

            }
        }
    }

    func testExpectation(_ json: JSON) -> Bool {
        expect(json).notTo(beNil())
        expect(json["name"] as? String).to(equal("Godzilla"))
        expect(json["age"] as? Int).to(equal(100))
        expect(json["extinct"] as? Bool).to(equal(true))
        return true
    }
}

struct SampleModel: Encodable, JSONRepresentable {
    let name: String
    let age: Int
    let extinct: Bool
}

class MyJSONEncoder: JSONEncoder {
    var isInvoked = false
    override func encode<T>(_ value: T) throws -> Data where T : Encodable {
        isInvoked = true
        return try JSONEncoder().encode(value)
    }
}
