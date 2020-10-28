//  Copyright © 2020 Tabcorp. All rights reserved.

import XCTest
@testable import TAB

class ServiceErrorTests: XCTestCase {

    func testIsNetworConnectionErrors() throws {
        XCTAssertTrue(getURLDomainServiceError(.notConnectedToInternet).isNetworkConnectionError)
        XCTAssertTrue(getURLDomainServiceError(.networkConnectionLost).isNetworkConnectionError)

        XCTAssertFalse(getURLDomainServiceError(.badServerResponse).isNetworkConnectionError)
        XCTAssertFalse(ServiceError.invalidResolvedUrl(URL(string: "http://test.com")!).isNetworkConnectionError)

        XCTAssertFalse(getRandomDomainServiceError(.notConnectedToInternet).isNetworkConnectionError)
        XCTAssertFalse(getRandomDomainServiceError(.networkConnectionLost).isNetworkConnectionError)
    }

}

private extension ServiceErrorTests {

    func getURLDomainServiceError(_ code:  URLError.Code) -> ServiceError {
        return ServiceError.underlying(NSError(domain: NSURLErrorDomain, code: code.rawValue, userInfo: [:]), nil)
    }

    /// Domain is not NSURLErrorDomain
    func getRandomDomainServiceError(_ code:  URLError.Code) -> ServiceError {
        return ServiceError.underlying(NSError(domain: "RandomDomain", code: code.rawValue, userInfo: [:]), nil)
    }
}
