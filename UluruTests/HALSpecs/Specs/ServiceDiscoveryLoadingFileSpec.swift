//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class ServiceDiscoveryLoadingFileSpec: QuickSpec {

    private var serviceDiscovery: ServiceDiscovery!

    override func spec() {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "DiscoveryTemplate", ofType: "json")!
        ServiceDiscovery.instantiate(apiRootURL: URL(fileURLWithPath: path)) { _ in }
        serviceDiscovery = ServiceDiscovery.shared()

        context("Init service discovery with baseURL") {
            it("should create properly") {
                expect(self.serviceDiscovery).notTo( beNil() )
            }
        }

        context("Set account number as variable for uriTemplate") {
            it("should constrcut url with account number correctly") {
                let url = self.serviceDiscovery.urlForEntryRelationNamed("account:acknowledge-anniversary", variables: ["accountNumber" : "828319"])
                expect(url?.absoluteString).to( equal("https://webapi.tab.com.au/v1/account-service/tab/accounts/828319/acknowledge/anniversary") )
            }
        }

        context("Set jurisdiction as variable for uriTemplate") {
            it("should constrcut url with jurisdiction correctly") {
                let url = self.serviceDiscovery.urlForEntryRelationNamed("betting:tsn:checkNonLoggedIn", variables: ["jurisdiction" : "NSW"])
                expect(url?.absoluteString).to( equal("https://webapi.tab.com.au/v1/tab-betting-service/NSW/ticket-enquiry") )
            }
        }

        context("Set default env parameters as variable for uriTemplate") {
            it("should constrcut url with default env parameters correctly") {
                let variables = [
                    "platform" : "iphone",
                    "platformVersion" : "11.4",
                    "version" : "10.23.1",
                    "applicationId" : "au.com.tabcorp.tab"
                ]
                let url = self.serviceDiscovery.urlForEntryRelationNamed("application:config", variables: variables)
                expect(url?.absoluteString).to( equal("https://api.beta.tab.com.au/v1/application-service/config?platform=iphone&applicationId=au.com.tabcorp.tab&version=10.23.1&platformVersion=11.4") )
            }
        }
    }
}
