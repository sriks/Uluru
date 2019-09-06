//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Foundation
import Quick
import Nimble
@testable import Uluru

class ServiceProvderSpec: QuickSpec {
    override func spec() {
        TestHelper.markWaitExpecationAsAPIRequest()
        var service: ServiceProvider!

        beforeEach {
            service = ServiceProvider()
        }

        context("Custom JSONDecoder") {
            var customDecoder: CustomDecoder!
            beforeEach {
                customDecoder = CustomDecoder()
                service = ServiceProvider(jsonDecoder: customDecoder)
            }

            it("uses the provided json decoder") {
                waitUntil { done in
                    let _ = service.request(TestAPIDefinition.justGet) { (result: Result<TestDecodableModel, Error>) in
                        done()
                    }
                }

                expect(customDecoder.isInvoked).to( beTrue() )
            }
        }

    }
}

