//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public class ServiceProvider<API: APIDefinition>: Service {

    // Maps an APIDefinition to a resolved Definition
    public typealias APIDefinitionResolver = (_ apiDefinition: API) -> APITarget

    // Maps a resolved definition to an URLRequest
    public typealias RequestMapper = (_ resolvedAPIDefinition: APITarget) -> Result<URLRequest, Error>

    public let apiDefinitionResolver: APIDefinitionResolver

    public let requestMapper: RequestMapper

    public let plugins: [ServicePluginType]

    public let jsonDecoder: JSONDecoder

    private let serviceExecutor: ServiceExecutable

    public init(apiDefinitionResolver: @escaping APIDefinitionResolver = ServiceProvider.defaultAPIDefinitionResolver,
                requestMapper: @escaping RequestMapper = ServiceProvider.defaultRequestMapper(),
                plugins: [ServicePluginType] = [],
                jsonDecoder: JSONDecoder = JSONDecoder(),
                serviceExecutor: ServiceExecutable = ExecutorURLSession.make()) {
        self.apiDefinitionResolver = apiDefinitionResolver
        self.requestMapper = requestMapper
        self.jsonDecoder = jsonDecoder
        self.serviceExecutor = serviceExecutor
        self.plugins = plugins
    }

    public func request<T>(_ api: API,
                           completion: @escaping (Result<T, Error>) -> Void) -> ServiceCancellable where T : Decodable {
        return self.requestData(api) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case let .success(successResponse):
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }
                    completion(self.decode(successResponse.data, using: self.jsonDecoder))
                }
                break
            case let .failure(errorResponse):
                completion(.failure(errorResponse.error))
                break
            }
        }
    }

    public func requestData(_ api: API,
                        completion: @escaping DataRequestCompletion) -> ServiceCancellable {
        let target = apiDefinitionResolver(api)
        switch requestMapper(target) {
        case let .success(urlRequest):
            return perform(urlRequest: urlRequest, api: api, target: target, completion: completion)
        case let .failure(error):
            completion(.failure(DataErrorResponse(error: error, data: nil, urlResponse: nil)))
            return DummyCancellable()
        }
    }

    private func perform(urlRequest: URLRequest,
                         api: API,
                         target: APITarget,
                         completion: @escaping DataRequestCompletion) -> ServiceCancellable {
        // Let plugins mutate request
        let mutatedRequest = plugins.reduce(urlRequest) { $1.mutate($0, api: api) }

        // Invoke plugins to inform we are about to send the request.
        self.plugins.forEach { $0.willSend(mutatedRequest, api: api) }

        let postRequestPlugins = plugins
        let onRequestCompletion: ServiceExecutionDataTaskCompletion = { (data, urlResponse, error) in
            let responseResult = self.map(data: data, urlResponse: urlResponse, error: error)

            // Invoke plugins to inform we did receive result.
            postRequestPlugins.forEach { $0.didReceive(responseResult, api: api) }

            // Invoke plugins to mutate result before sending off to caller.
            let mutatedResult = postRequestPlugins.reduce(responseResult) { $1.willFinish($0, api: api) }

            // Invoke completion
            completion(mutatedResult)
        }

        if let placeholderData = api.placeholderData {
            // Placeholder data
            let ourResponse = HTTPURLResponse(url: mutatedRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            completion(.success(DataSuccessResponse(data: placeholderData, urlResponse: ourResponse)))
            return DummyCancellable()
        } else {
            // Execute request
            return serviceExecutor.execute(dataRequest: mutatedRequest, completion: onRequestCompletion)
        }
    }

    private func map(data: Data?, urlResponse: HTTPURLResponse?, error: Error?) -> DataResult {
        switch (urlResponse, data, error) {

            // All good
            case let (.some(urlResponse), data, .none):
                return .success(DataSuccessResponse(data: data ?? Data(), urlResponse: urlResponse))

            // Errored out but with some data.
            case let (.some(urlResponse), data, .some(error)):
                return .failure(DataErrorResponse(error: error, data: data, urlResponse: urlResponse))

            // Error without data
            case let (_, _, .some(error)):
                return .failure(DataErrorResponse(error: error, data: nil, urlResponse: nil))

            // Something wierd so falling back to nsurlerror.
            default:
                return .failure(DataErrorResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil), data: nil, urlResponse: nil))
        }
    }

    private func decode<T: Decodable>(_ data: Data, using decoder: JSONDecoder) -> Result<T, Error> {
        do {
            let decoded: T = try decoder.decode(T.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }
}

struct DummyCancellable: ServiceCancellable {
    let isCancelled: Bool = false
    func cancel() {}
}

