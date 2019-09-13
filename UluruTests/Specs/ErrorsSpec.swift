//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

// Tests error expectations
class ErrorsSpec: QuickSpec {

    override func spec() {

        describe("Expected Errors") {
            var service: ServiceProvider<ErrorAPIDefinition>!
            let someNSError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
            let someResponse = DataResponse(data: Data(), request: URLRequest(url: URL(string: "https://apple.com")!), urlResponse: nil)

            beforeEach {
                service = ServiceProvider()
            }

            it("should return .underlying error when server is not reachable") {
                var actual: ServiceError!
                waitUntil { done in
                    let _ = service.request(.thisDontExist, expecting: EmptyDecodableModel.self) { (result) in
                        actual = result.error()
                        done()
                    }
                }

                expect(actual).notTo( beNil() )
                expect(actual).to( beSameError(.underlying(someNSError, nil)) )
            }

            it("should return .parsing for unexpected response") {
                struct NotTheExpectedModel: Decodable {
                    let bar: String
                }
                var actual: ServiceError?
                waitUntil { done in
                    let _ = service.request(.failParsing(params: EchoParams.make()), expecting: NotTheExpectedModel.self, completion: { (result) in
                        actual = result.error()
                        done()
                    })
                }

                expect(actual).notTo( beNil() )
                expect(actual).to( beSameError( .parsing(someNSError, someResponse) ) )
            }

        }
    }
}

