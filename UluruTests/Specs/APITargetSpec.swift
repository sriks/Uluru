//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class APITargetSpec: QuickSpec {
    override func spec() {
        describe("APITarget") {
            let anAPIDefintion: PostmanEcho = .justGet

            it("should create a valid APITarget from an APIDefinition") {
                let aResolvedURL = anAPIDefintion.baseURL
                let target = APITarget.makeFrom(anAPIDefintion, resolvedURL: aResolvedURL)

                expect(target.url).to( equal(aResolvedURL) )
                expect(target.path).to( equal(anAPIDefintion.path) )
                expect(target.method).to( equal(anAPIDefintion.method) )
                let encodingMatched: Bool = {
                    switch target.encoding {
                    case .ignore:
                        return true
                    default:
                        return false
                    }
                }()
                expect(encodingMatched).to( beTrue() )
                // Since the apiDefinition has nil headers.
                expect(target.headers).to( beNil() )
            }

            it("should append headers as expected") {
                let aResolvedURL = anAPIDefintion.baseURL
                var target = APITarget.makeFrom(anAPIDefintion, resolvedURL: aResolvedURL)
                let expectedHeaders = ["animal": "Godzilla", "place": "Sea of Japan"]
                expectedHeaders.forEach {
                    target.add(httpHeader: $0.key, value: $0.value)
                }
                expect(target.headers).to( equal(expectedHeaders) )
            }
        }
    }
}
