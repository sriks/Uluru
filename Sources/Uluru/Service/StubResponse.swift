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

    /// Produces a sucess 200 network response reading from supplied json file. Use this to simuate a successful network attempt.
    static func networkResponseFromFile(_ fileName: String, target: APITarget, in bundle: Bundle) -> StubResponse {
        let data = StubUtils.data(from: fileName, in: bundle)
        assert(data != nil, "JSON Data not found at \(fileName) in bundle \(bundle)")
        return networkResponseFromData(data!, target: target, in: bundle)
    }

    /// Produces a sucess 200 network response reading from supplied data. Use this to simuate a successful network attempt.
    static func networkResponseFromData(_ data: Data, target: APITarget, in bundle: Bundle) -> StubResponse {
        let urlResponse = HTTPURLResponse(url: target.url, statusCode: 200, httpVersion: nil, headerFields: nil)
        assert(urlResponse != nil, "cannot construct UrlResponse from \(target.url)")
        return .networkResponse(urlResponse!, data)
    }

    /// Produces a network timedout response
    static func networkTimedoutError() -> StubResponse {
        return .networkError(NSError(domain: NSURLErrorDomain,
                                     code: NSURLErrorTimedOut,
                                     userInfo: [NSLocalizedDescriptionKey: "Stub - The connection timed out."]))
    }
}

public class StubUtils {
    public static func data(from filename: String, ofType ext: String = "json", in bundle: Bundle) -> Data? {
        guard let path = StubUtils.path(for: filename, ofType: "json", in: bundle) else { return nil }
        return try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
    }

    public static func json(from filename: String, in bundle: Bundle) -> JSON? {
        guard let ourData = StubUtils.data(from: filename, in: bundle) else { return nil }
        return try? JSONSerialization.jsonObject(with: ourData, options: []) as? [String : Any]
    }

    static func path(for fileName: String, ofType ext: String = "json", in bundle: Bundle) -> String? {
        return bundle.path(forResource: fileName, ofType: ext)
    }
}

