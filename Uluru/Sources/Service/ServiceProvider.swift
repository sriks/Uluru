//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// A JSON response parser.
public protocol ResponseParser {
    func parse<T: Decodable>(_ response: DataResponse) -> Result<T, ParsingError>
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

public class ServiceProvider<API: APIDefinition>: Service {

    // Maps an APIDefinition to an APITarget with a resolved URL.
    public typealias APITargetResolver = (_ api: API) -> Result<APITarget, ServiceError>

    // Maps a resolved definition to an URLRequest.  
    public typealias RequestMapper = (_ resolvedAPIDefinition: APITarget) -> Result<URLRequest, ServiceError>

    public let apiTargetResolver: APITargetResolver

    public let requestMapper: RequestMapper

    public let plugins: [ServicePluginType]

    public let stubStrategy: StubStrategy

    public let parser: ResponseParser.Type

    public let completionStrategy: RequestCompletionStrategyProvidable

    private let serviceExecutor: ServiceExecutable

    public init(apiTargetResolver: @escaping APITargetResolver = ServiceProvider.defaultAPITargetResolver(),
                requestMapper: @escaping RequestMapper = ServiceProvider.defaultRequestMapper(),
                plugins: [ServicePluginType] = [],
                stubStrategy: StubStrategy = .dontStub,
                parser: ResponseParser.Type = ServiceProvider.defaultParser(),
                completionStrategy: RequestCompletionStrategyProvidable = ServiceProvider.defaultCompletionStrategyProvider(),
                serviceExecutor: ServiceExecutable = ExecutorURLSession.make()) {
        self.apiTargetResolver = apiTargetResolver
        self.requestMapper = requestMapper
        self.plugins = plugins
        self.stubStrategy = stubStrategy
        self.parser = parser
        self.completionStrategy = completionStrategy
        self.serviceExecutor = serviceExecutor
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
                    self.performParsing(successResponse, using: self.parser.make(), completion: completion)
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    public func requestData(_ api: API,
                        completion: @escaping DataRequestCompletion) -> ServiceCancellable {
        let cancellable = ServiceCancellableWrapper()

        // Get a target representation
        let targetResult = apiTargetResolver(api)
        var target: APITarget?
        switch targetResult {
        case .success(let ourTarget):
            target = ourTarget
        case .failure(let error):
            completion(.failure(error))
        }

        if let ourTarget = target {
            // Map target to an urlrequest.
            switch requestMapper(ourTarget) {
            case let .success(urlRequest):
                cancellable.inner = perform(urlRequest: urlRequest, api: api, target: ourTarget, completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
        return cancellable
    }

    private func perform(urlRequest: URLRequest,
                         api: API,
                         target: APITarget,
                         completion: @escaping DataRequestCompletion) -> ServiceCancellable {
        let canceller = ServiceCancellableWrapper()

        // Let plugins mutate request
        let mutatedRequest = plugins.reduce(urlRequest) { $1.mutate($0, api: api) }

        // Invoke plugins to inform we are about to send the request.
        self.plugins.forEach { $0.willSubmit(mutatedRequest, api: api) }

        let postRequestPlugins = plugins
        let onRequestCompletion: ServiceExecutionDataTaskCompletion = { [weak self] (data, urlResponse, error) in
            guard let self = self else { return }

            let responseResult = self.map(data: data, urlResponse: urlResponse, error: error, request: mutatedRequest)

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
                    // We need to keep a hold of cancellable since this is a new request.
                    canceller.inner = self.perform(urlRequest: urlRequest, api: api, target: target, completion: completion)
                }
            })
        }

        if let placeholderData = api.placeholderData {
            // Placeholder data
            let ourResponse = HTTPURLResponse(url: mutatedRequest.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            completion(.success(DataResponse(data: placeholderData, request: mutatedRequest, urlResponse: ourResponse)))
            return ServiceCancellableWrapper()
        } else {
            // Execute request
            canceller.inner = execute(target, request: mutatedRequest, stubStrategy: stubStrategy, completion: onRequestCompletion)
        }
        return canceller
    }

    private func execute(_ target: APITarget,
                         request: URLRequest,
                         stubStrategy: StubStrategy,
                         completion: @escaping ServiceExecutionDataTaskCompletion) -> ServiceCancellable {
        switch stubStrategy {
        case .dontStub:
            return serviceExecutor.execute(dataRequest: request, completion: completion)
        case .stub(let delay, let response):
            return executeStub(target, urlRequest: request, delay: delay, stubResponseProvider: response, completion: completion)
        }
    }

    private func executeStub(_ target: APITarget,
                             urlRequest: URLRequest,
                             delay: TimeInterval,
                             stubResponseProvider: @escaping StubReponseProvider,
                             completion: @escaping ServiceExecutionDataTaskCompletion) -> ServiceCancellable {
        // Here we have to send a wrapper canceller which works for .continueCourse
        let canceller = ServiceCancellableWrapper()

        let stubInvocation = { [weak self] in
            guard let self = self else { return }
            let stubResponse = stubResponseProvider(target)
            switch stubResponse {
            case .network(let response, let data):
                completion(data, response, nil)
            case .error(let error):
                completion(nil, nil, error)
            case .continueCourse:
                // Since this request goes to executor we need to update the inner canceller.
                canceller.inner = self.serviceExecutor.execute(dataRequest: urlRequest, completion: completion)
            }
        }

        if delay > 0 {
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + delay) {
                stubInvocation()
            }
        } else {
            stubInvocation()
        }

        return canceller
    }

    private func map(data: Data?, urlResponse: HTTPURLResponse?, error: Error?, request: URLRequest) ->
        DataResult {
            switch (urlResponse, data, error) {
            // All good - request went through successfully.
            case let (.some(urlResponse), data, .none):
                let theResponse = DataResponse(data: data ?? Data(), request: request, urlResponse: urlResponse)
                return .success(theResponse)

            // Request failed with error
            case let (.some(urlResponse), _, .some(error)):
                let theResponse = DataResponse(data: data ?? Data(), request: request, urlResponse: urlResponse)
                let theError = ServiceError.underlying(error, theResponse)
                return .failure(theError)

            // Error without data
            case let (_, _, .some(error)):
                let theError = ServiceError.underlying(error, nil)
                return .failure(theError)

            // Something wierd - fallback to unknown error.
            default:
                let theError = ServiceError.underlying(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil), nil)
                return .failure(theError)
            }
    }

    private func performParsing<T: Decodable>(_ response: DataResponse, using parser: ResponseParser, completion: @escaping APIRequestCompletion<T>) {
        let result: Result<T, ServiceError> = self.decode(response, using: parser)
        switch result {
        case .success(let decoded):
            completion(.success(.init(parsed: decoded, dataResponse: response)))
        case .failure(let error):
            completion(.failure(error))
        }
    }

    private func decode<T>(_ response: DataResponse, using parser: ResponseParser) -> Result<T, ServiceError> where T: Decodable {
        let result: Result<T, ParsingError> = parser.parse(response)
        switch result {
        case .success(let parsed):
            return .success(parsed)
        case .failure(let error):
            switch error {
            case .parsing(let theError):
                return .failure(.parsing(theError, response))
            case .response(let obj):
                return .failure(.response(response, obj))
            }
        }
    }
}
