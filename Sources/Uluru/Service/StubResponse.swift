//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// Defines a stub response
public enum StubResponse {
    /// A network response to indicate the request went through.
    case networkResponse(HTTPURLResponse, Data)

    /// Network error like failed or timeout.
    case networkError(NSError)

    /// Continue course with executing a real network request. Use this to conditionally stub a response.
    case continueCourse
}

// MARK: - StubResponse Helpers
public extension StubResponse {

    /// Produces a network response reading from supplied json file. Use this to simuate a successful network attempt.
    static func networkResponseFromFile(_ fileName: String, target: APITarget, in bundle: Bundle) -> StubResponse {
        let data = StubUtils.data(from: fileName, in: bundle)
        assert(data != nil, "JSON Data not found at \(fileName) in bundle \(bundle)")
        let urlResponse = HTTPURLResponse(url: target.url, statusCode: 200, httpVersion: nil, headerFields: nil)
        assert(urlResponse != nil, "cannot construct UrlResponse from \(target.url)")
        return .networkResponse(urlResponse!, data!)
    }


    /// Produces a network timedout response
    static func networkTimedoutError() -> StubResponse {
        return .networkError(NSError(domain: NSURLErrorDomain,
                                     code: NSURLErrorTimedOut,
                                     userInfo: [NSLocalizedDescriptionKey: "Stub - The connection timed out."]))
    }
}

class StubUtils {
    static func data(from filename: String, ofType ext: String = "json", in bundle: Bundle) -> Data? {
        guard let path = StubUtils.path(for: filename, ofType: "json", in: bundle) else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
    }

    static func path(for fileName: String, ofType ext: String = "json", in bundle: Bundle) -> String? {
        return bundle.path(forResource: fileName, ofType: ext)
    }
}

