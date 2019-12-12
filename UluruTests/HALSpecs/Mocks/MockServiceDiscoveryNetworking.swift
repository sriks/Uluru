//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
@testable import Uluru

class MockServiceDiscoveryNetworking: ServiceDiscoveryRequestable {

    private let apiRootURL: URL?
    private let bearerToken: String?
    private let mockDiscoveryDict: [String : Any] = [
        "homepage" : "www.tab.com.au",
        "_links" : ["account:account-number-retrieval" : "https://webapi.tab.com.au/v1/account-service/tab/accounts/account-number-retrieval",
                    "account:acknowledge-anniversary" : "https://webapi.tab.com.au/v1/account-service/tab/accounts/{accountNumber}/acknowledge/anniversary",
                    "betting:tsn:checkNonLoggedIn": "https://webapi.tab.com.au/v1/tab-betting-service/{jurisdiction}/ticket-enquiry",
                    "application:config": "https://api.beta.tab.com.au/v1/application-service/config{?platform,applicationId,version,platformVersion,accountId,sessionId}"
        ]
    ]

    required init(apiRootURL: URL?, bearerToken: String?) {
        self.apiRootURL = apiRootURL
        self.bearerToken = bearerToken
    }

    func requestServiceDiscovery(_ completion: @escaping (URL?, Data?, RequestServiceDiscoveryError?) -> Void) {
        guard let _ = apiRootURL, let _ = bearerToken else {
            completion(nil, nil, .unknownError)
            return
        }

        do {
            let discoveryData = try JSONSerialization.data(withJSONObject: mockDiscoveryDict, options: .prettyPrinted)
            completion(nil, discoveryData, nil)
        } catch {
            completion(nil, nil, .unknownError)
        }
    }
}
