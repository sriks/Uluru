//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Quick
import Nimble
@testable import Uluru

class ServiceDiscoveryLoadingFileSpec: QuickSpec {

    private var serviceDiscovery: ServiceDiscoveryType!

    override func spec() {
        ServiceDiscovery.createInstance(apiRootURL: .localDiscoveryURL) { result in
            self.serviceDiscovery = try? result.get()
        }

        context("Init service discovery with baseURL") {
            it("should create properly") {
                expect(self.serviceDiscovery).notTo( beNil() )
            }
        }

        context("Set account number as variable for uriTemplate") {
            it("should constrcut url with account number correctly") {
                let url = self.serviceDiscovery.urlForEntryRelationNamed("account:acknowledge-anniversary", variables: ["accountNumber" : "828319"])
                expect(url?.absoluteString).to( equal("https://uat02.beta.tab.com.au/v1/account-service/tab/accounts/828319/acknowledge/anniversary") )
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
                expect(url?.absoluteString).to( equal("https://uat02.beta.tab.com.au/v1/application-service/config?platform=iphone&applicationId=au.com.tabcorp.tab&version=10.23.1&platformVersion=11.4") )
            }
        }
    }
}

extension URL {
    static var localDiscoveryURL: URL {
        let path = Bundle.ourBundle.path(forResource: "uat02", ofType: "json")!
        return URL(fileURLWithPath: path)
    }
}

extension Bundle {
    static var ourBundle: Bundle {
        Bundle(for: ServiceDiscoveryLoadingFileSpec.self)
    }
}
