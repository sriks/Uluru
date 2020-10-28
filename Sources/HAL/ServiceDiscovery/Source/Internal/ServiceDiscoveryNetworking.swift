//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

protocol ServiceDiscoveryRequestable {
    init(apiRootURL: URL, bearerToken: String?)
    func requestServiceDiscovery(_ completion: @escaping (URL, Data?, RequestServiceDiscoveryError?) -> Void)
}

enum RequestServiceDiscoveryError: Error {
    case serverError
    case unknownError
}

class ServiceDiscoveryNetworking: ServiceDiscoveryRequestable {

    private let apiRootURL: URL
    private let bearerToken: String?
    private let session = URLSession.shared

    required init(apiRootURL: URL, bearerToken: String?) {
        self.apiRootURL = apiRootURL
        self.bearerToken = bearerToken
    }

    func requestServiceDiscovery(_ completion: @escaping (URL, Data?, RequestServiceDiscoveryError?) -> Void) {
        let url = apiRootURL
        let task = session.dataTask(with: urlRequest(url), completionHandler: { data, response, error -> Void in
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode),
                let data = data
                else {
                    completion(url, nil, RequestServiceDiscoveryError.serverError)
                    return
            }
            completion(url, data, nil)
        })
        task.resume()
    }

    private func urlRequest(_ apiRootURL: URL) -> URLRequest {
        var request = URLRequest(url: apiRootURL)
        request.httpMethod = "GET"
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = 3
        if let bearerToken = bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
