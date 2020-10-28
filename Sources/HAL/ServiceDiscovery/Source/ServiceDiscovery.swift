//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public typealias ServiceDiscoveryCompletionBlock = (Result<Void, DiscoveryError>) -> Void
typealias ServiceDiscoveryCreationCompletionBlock = (Result<ServiceDiscoveryType, DiscoveryError>) -> Void
public class ServiceDiscovery: ServiceDiscoveryType {

    private let apiRootURL: URL
    private let bearerToken: String?
    private let dataProvider: DataProvidable
    private static var sharedInstance: ServiceDiscoveryType?

    /// Instantiates Service Discovery. Use this before `ServiceDiscovery.shared()`
    /// - Parameters:
    ///   - apiRootURL: The API root url. For example `https://uat02.beta.tab.com.au/v1`. This will also accept a file:// url which is handy for tests.
    ///   - bearerToken: An optional bearer token.
    ///   - completion: The completion to indicate if loading service discovery is success or not.
    ///   * You should check the completion before using ServiceDiscovery. However the instance will be created either success or failure.
    ///   * Do not access `shared()` within the completion, since this completion is only to indicate discovery loading status.
    public static func instantiate(apiRootURL: URL, bearerToken: String? = nil, completion: ServiceDiscoveryCompletionBlock? = nil) {
        sharedInstance = ServiceDiscovery.createInstance(apiRootURL: apiRootURL, bearerToken: bearerToken, completion: completion)
    }

    /// Internal mechanism to create an instance of service discovery. This is not shared but a always creates a new instance.
    static func createInstance(apiRootURL: URL, bearerToken: String? = nil, completion: ServiceDiscoveryCompletionBlock? = nil) -> ServiceDiscovery {
        var ourInstance: ServiceDiscovery!
        let service = ServiceDiscoveryNetworking(apiRootURL: apiRootURL, bearerToken: bearerToken)
        let persistence = ServiceDiscoveryPersistence(fileURL: apiRootURL)
        let dataProvider = ServiceDiscoveryDataProvider(service: service, persistence: persistence)
        ourInstance = ServiceDiscovery(apiRootURL: apiRootURL, bearerToken: bearerToken, dataProvider: dataProvider)
        // Start loading discovery after the instance is created.
        dataProvider.load(completion ?? { _ in })
        return ourInstance
    }

    init(apiRootURL: URL, bearerToken: String?, dataProvider: DataProvidable) {
        self.apiRootURL = apiRootURL
        self.bearerToken = bearerToken
        self.dataProvider = dataProvider
    }

    private func halLinkForEntryRelationNamed(_ name: String) -> __STHALLink? {
        return dataProvider.serviceDiscoveryResource?.links.link(forRelationNamed: name)
    }

    private func serviceDiscoveryOverlayForEntryRelationNamed(_ name: String) -> __STURITemplate? {
        return dataProvider.serviceDiscoveryOverlay[name] as? __STURITemplate
    }

    private func serviceDiscoveryUnderlayForEntryRelationNamed(_ name: String) -> __STURITemplate? {
        return dataProvider.serviceDiscoveryUnderlay[name] as? __STURITemplate
    }
}

// MARK: ServiceDiscoveryOverlayConfigurable
extension ServiceDiscovery {

    public func setServiceDiscoveryOverlayEntryRelation(with name: String, uriTemplate: String) {
        dataProvider.updateOverlay(with: name, uriTemplate: uriTemplate)
    }

    public func removeServiceDiscoveryOverlayEntryRelation(with name: String) {
        dataProvider.removeOverlay(for: name)
    }
}

// MARK: ServiceDiscoveryUnderlayConfigurable
extension ServiceDiscovery {

    public func setServiceDiscoveryUnderlayEntryRelation(with name: String, uriTemplate: String) {
        dataProvider.updateUnderlay(with: name, uriTemplate: uriTemplate)
    }

    public func removeServiceDiscoveryUnderlayEntryRelation(with name: String) {
        dataProvider.removeUnderlay(for: name)
    }
}

// MARK: ServiceDiscoveryQueryable
extension ServiceDiscovery {

    public func hasURLForEntryRelationNamed(_ name: String) -> Bool {
        if let _ = serviceDiscoveryOverlayForEntryRelationNamed(name) {
            return true
        } else if let _ = halLinkForEntryRelationNamed(name) {
            return true
        } else if let _ = serviceDiscoveryUnderlayForEntryRelationNamed(name) {
            return true
        }
        return false
    }

    public func urlVariableNamesForEntryRelationNamed(_ name: String) -> [String]? {
        if let overlay = serviceDiscoveryOverlayForEntryRelationNamed(name) {
            return overlay.variableNames as? [String]
        } else if let link = halLinkForEntryRelationNamed(name) {
            return link.templateVariableNames as? [String]
        } else if let underlay = serviceDiscoveryUnderlayForEntryRelationNamed(name) {
            return underlay.variableNames as? [String]
        }
        return nil
    }

    public func urlForEntryRelationNamed(_ name: String, variables: [String: Any]?) -> URL? {
        if let overlay = serviceDiscoveryOverlayForEntryRelationNamed(name) {
            return overlay.urlByExpanding(withVariables: variables)
        }

        if let link = halLinkForEntryRelationNamed(name) {
            return link.url(withVariables: variables)
        }

        if let underlay = serviceDiscoveryUnderlayForEntryRelationNamed(name) {
            return underlay.urlByExpanding(withVariables: variables)
        }
        return nil
    }
}

// MARK: ServiceDiscoveryURIResolvable
extension ServiceDiscovery {
    public func urlForHALLink(_ uri: String, variables: [String: Any]?) -> URL? {
        let halLink = HALLinkRepresentation(template: __STURITemplate(string: uri))
        return halLink.url(withVariables: variables)
    }
}

// MARK: ServiceDiscoveryRefreshable
extension ServiceDiscovery {

    public func refreshServiceDiscoveryIfNecessary(_ completion: @escaping ServiceDiscoveryCompletionBlock) {
        dataProvider.requestServiceDiscovery(completion)
    }
}

extension ServiceDiscovery {

    public static func shared() -> ServiceDiscoveryType {
        if let ourInstance = sharedInstance {
            return ourInstance
        }
        fatalError("shared instance invoked before instantiate")
    }
}
