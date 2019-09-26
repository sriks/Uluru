//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public struct JSONAPILogger: ServicePluginType {

    let tag = "Uluru-JSONLogger"

    public init() {
        // left blank
    }

    public func willSubmit(_ request: URLRequest, api: APIDefinition) {
        print("\(tag): willSubmit \(request)")
    }

    public func didReceive(_ result: DataResult, api: APIDefinition) {
        print("\(tag) didReceive response")
        switch result {
        case .success(let response):
            print("\(tag): \(response.request)")
            print("\(tag): \(String(describing: response.urlResponse))")
            print("\(tag): \(String(describing: response.data.prettyPrintedJSONString))")
        case .failure(let error):
            print("\(tag): failed with error \(error)")
        }
    }
}

// Credit https://gist.github.com/cprovatas/5c9f51813bc784ef1d7fcbfb89de74fe
extension Data {

    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}
