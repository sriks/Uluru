//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru
@testable import HALUluru

class HALAPITargetSpec: QuickSpec {
    override func spec() {
        TestHelper.markWaitExpecationAsAPIRequest()

        beforeSuite {
            waitUntil() { done in
                ServiceDiscovery.instantiate(apiRootURL: URL(string: "https://api.beta.tab.com.au/v1")!) { result in
                    print("discovery: \(result)")
                    switch result {
                    case .success:
                        done()
                    case .failure(let error):
                        fatalError(error.errorDescription ?? "unable to load discovery")
                    }
                }
            }
        }

        context("HAL Target Resolver") {
            it("should resolve url as expected") {
                let closure = ServiceRequester<SampleHALAPI>.makeHALTargetResolver()
                let result = closure(.fooBar(promoGroup: PromoGroup(promoGroupId: "12345")))
                let apiTarget = try! result.get()
                let expectedURL = URL(string: "https://api.beta.tab.com.au/v1/invenue-service/promo-groups/12345")!
                expect(apiTarget.url).to(equal( expectedURL ))
            }
        }
    }
}

struct PromoGroup: Codable, JSONRepresentable {
    let promoGroupId: String
}

enum SampleHALAPI {
    case fooBar(promoGroup: JSONRepresentable)
}

// Using this enitity "invenue:promo-groups:update":"https://api.beta.tab.com.au/v1/invenue-service/promo-groups/{promoGroupId}",
extension SampleHALAPI: HALAPIDefinition, RequiresHALEntityResolution {

    var entityResolution: EntityResolution {
        switch self {
        case .fooBar(let promoGroup):
            return .namedEntity(.init(name: "invenue:promo-groups:update", variables: promoGroup))
        }
    }

    var method: HTTPMethod {
        return .GET
    }

    var encoding: EncodingStrategy {
        return .ignore
    }
}
