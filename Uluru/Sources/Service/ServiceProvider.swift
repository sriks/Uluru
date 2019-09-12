//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// A JSON response parser.
public protocol ResponseParser {
    func parse<T: Decodable>(_ response: DataSuccessResponse) throws -> Result<T, ServiceError>
    static func make() -> ResponseParser
}

public enum StubResponse {
    /// A network response to indicate the request went through.
    case network(response: HTTPURLResponse, data: Data)

    /// Network error like failed or timeout.
    case error(error: NSError)

    /// Continue course with executing a real network request. Use this to conditionally stub a response.
    case continueCourse
}

public typealias StubReponseProvider = (_ apiTarget: APITarget) -> StubResponse
public enum StubStrategy {
    case dontStub
    case stub(delay: TimeInterval, response: StubReponseProvider)
}


public enum RequestCompletionStrategy {
    case goahead
    case retry
}

public typealias ShouldFinishDecision = (_ decision: RequestCompletionStrategy) -> Void
public protocol RequestCompletionStrategyProvidable {
    func shouldFinish(_ result: DataResult, api: APIDefinition, decision: @escaping ShouldFinishDecision)
}

public class ServiceProvider<API: APIDefinition>: Service {

    // Maps an APIDefinition to a resolved Definition
    public typealias APIDefinitionResolver = (_ apiDefinition: API) -> APITarget

    // Maps a resolved definition to an URLRequest
    public typealias RequestMapper = (_ resolvedAPIDefinition: APITarget) -> Result<URLRequest, Error>

    public let apiDefinitionResolver: APIDefinitionResolver

    public let requestMapper: RequestMapper

    public let plugins: [ServicePluginType]

    public let stubStrategy: StubStrategy

    public let parser: ResponseParser.Type

    public let completionStrategy: RequestCompletionStrategyProvidable

    private let serviceExecutor: ServiceExecutable

    public init(apiDefinitionResolver: @escaping APIDefinitionResolver = ServiceProvider.defaultAPIDefinitionResolver,
                requestMapper: @escaping RequestMapper = ServiceProvider.defaultRequestMapper(),
                plugins: [ServicePluginType] = [],
                stubStrategy: StubStrategy = .dontStub,
                parser: ResponseParser.Type = ServiceProvider.defaultParser,
                completionStrategy: RequestCompletionStrategyProvidable = ServiceProvider.defaultCompletionStrategyProvider(),
                serviceExecutor: ServiceExecutable = ExecutorURLSession.make()) {
        self.apiDefinitionResolver = apiDefinitionResolver
        self.requestMapper = requestMapper
        self.stubStrategy = stubStrategy
        self.parser = parser
        self.completionStrategy = completionStrategy
        self.serviceExecutor = serviceExecutor
        self.plugins = plugins
    }

    public func request<T: Decodable>(_ api: API,
                                      expecting: T.Type,
                                      completion: @escaping APIRequestCompletion<T>) -> ServiceCancellable {

        return self.requestData(api) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case let .success(successResponse):
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else { return }
                    completion(self.decode(successResponse, using: self.parser.make()))
                }
                break
            case let .failure(errorResponse):
                completion(.failure(.requestFailed(errorResponse)))
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
        self.plugins.forEach { $0.willSubmit(mutatedRequest, api: api) }

        let postRequestPlugins = plugins
        let onRequestCompletion: ServiceExecutionDataTaskCompletion = { [weak self] (data, urlResponse, error) in
            guard let self = self else { return }

            let responseResult = self.map(data: data, urlResponse: urlResponse, error: error)

            // Invoke plugins to inform we did receive result.
            postRequestPlugins.forEach { $0.didReceive(responseResult, api: api) }

            // Invoke plugins to mutate receieved result.
            let mutatedResult = postRequestPlugins.reduce(responseResult) { $1.mutate($0, api: api) }

            // Invoke decision maker
            self.completionStrategy.shouldFinish(mutatedResult, api: api, decision: { [weak self] decision in
                guard let self = self else { return }

                switch decision {
                case .goahead:
                    // Invoke completion
                    completion(mutatedResult)
                case .retry:
                    // Retry the request
                    // TODO: We need to keep a hold of cancellable to resuse it.
                    let _ = self.perform(urlRequest: urlRequest, api: api, target: target, completion: completion)
                }
            })
        }

        if let placeholderData = api.placeholderData {
            // Placeholder data
            let ourResponse = HTTPURLResponse(url: mutatedRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            completion(.success(DataSuccessResponse(data: placeholderData, urlResponse: ourResponse)))
            return DummyCancellable()
        } else {
            // Execute request
            return execute(target, request: mutatedRequest, stubStrategy: stubStrategy, completion: onRequestCompletion)
        }
    }

    private func execute(_ target: APITarget, request: URLRequest, stubStrategy: StubStrategy, completion: @escaping ServiceExecutionDataTaskCompletion) -> ServiceCancellable {
        switch stubStrategy {
        case .dontStub:
            return serviceExecutor.execute(dataRequest: request, completion: completion)
        case .stub(let delay, let response):
            executeStub(target, urlRequest: request, delay: delay, responseProvider: response, completion: completion)
            // Here we have to send a wrapper canceller which works for .continueCourse
            return DummyCancellable()
        }
    }

    private func executeStub(_ target: APITarget,
                             urlRequest: URLRequest,
                             delay: TimeInterval,
                             responseProvider: @escaping StubReponseProvider,
                             completion: @escaping ServiceExecutionDataTaskCompletion) {
        let stubInvocation = { [weak self] in
            guard let self = self else { return }
            let stubResponse = responseProvider(target)
            switch stubResponse {
            case .network(let response, let data):
                completion(data, response, nil)
            case .error(let error):
                completion(nil, nil, error)
            case .continueCourse:
                let _ = self.serviceExecutor.execute(dataRequest: urlRequest, completion: completion)
            }
        }

        if delay > 0 {
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + delay) {
                stubInvocation()
            }
        } else {
            stubInvocation()
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

    private func decode<T: Decodable>(_ response: DataSuccessResponse, using parser: ResponseParser) -> Result<T, ServiceError> {
        do {
            return try parser.parse(response)
        } catch {
            return .failure(.decodingFailed(response, error))
        }
    }
}

struct DummyCancellable: ServiceCancellable {
    let isCancelled: Bool = false
    func cancel() {}
}

