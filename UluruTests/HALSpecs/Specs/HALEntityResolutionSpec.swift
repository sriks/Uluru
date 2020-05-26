//Copyright © 2020 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class HALEntityResolutionSpec: QuickSpec {

    override func spec() {

        describe("URLLink") {
            let expectedURL = URL(string: "https://uat02.beta.tab.com.au/v1/account-service/tab/accounts/123456/transactions?count=10")!
            
            context("constructed from template URI") {
                struct Params: Encodable, JSONRepresentable {
                    let accountNumber: UInt64
                    let count: Int
                }
                let templateURLLink = URIEntity("https://uat02.beta.tab.com.au/v1/account-service/tab/accounts/{accountNumber}/transactions{?count}",
                                      variables: Params(accountNumber: 123456, count: 10))
                let resolvedURL = templateURLLink.resolved()
                it("should resolve as expected") {
                    expect(resolvedURL).to( equal(expectedURL) )
                }
            }

            context("constructed from url") {
                let urlLink = URIEntity(expectedURL)
                let resolvedURL = urlLink.resolved()

                it("should resolve as expected") {
                    expect(resolvedURL).to( equal(expectedURL) )
                }
            }
        }

    }

}

