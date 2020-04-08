//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class ServiceDiscoveryPersistenceSpec: QuickSpec {

    private let persistence = ServiceDiscoveryPersistence(fileURL: nil)
    private let mockDiscoveryDict: [String : Any] = [
        "homepage" : "www.tab.com.au",
        "_links" : ["account:account-number-retrieval" : "https://webapi.tab.com.au/v1/account-service/tab/accounts/account-number-retrieval",
                    "account:acknowledge-anniversary" : "https://webapi.tab.com.au/v1/account-service/tab/accounts/{accountNumber}/acknowledge/anniversary"
        ]
    ]

    override func spec() {
        context("Save service dicovery template locally") {
            it("should successfully save mock service discovery template locally") {
                if let mockDiscoveryResource = STHALResource(dictionary: self.mockDiscoveryDict, baseURL: nil, options: .allowSimplifiedLinks) {
                    self.persistence.saveServiceDiscoveryToPersistence(resource: mockDiscoveryResource) { (success, error) in
                        expect(success).to( beTrue() )
                        expect(error).to( beNil() )
                    }
                }
            }
        }

        context("Load service dicovery template from local") {
            it("should load mock service discovery template into memory correctly") {
                self.persistence.loadServiceDiscoveryFromPersistence { (resource, error) in
                    expect(resource).notTo( beNil() )
                    expect(resource?.payload).notTo( beNil() )
                    expect(resource?.links.relationNames.count).to( equal(2) )
                    expect(error).to( beNil() )
                }
            }
        }
    }
}
