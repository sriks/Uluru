//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public typealias ServiceDiscoveryCompletionBlock = (Result<Void, DiscoveryError>) -> Void

public class ServiceDiscovery {

    private let apiRootURL: URL?
    private let bearerToken: String?
    private let dataProvider: DataProvidable
    private static var sharedInstance: ServiceDiscovery?

    public static func instantiate(apiRootURL: URL?, bearerToken: String? = nil, completion: ServiceDiscoveryCompletionBlock?) {
        let service = ServiceDiscoveryNetworking(apiRootURL: apiRootURL, bearerToken: bearerToken)
        let persistence = ServiceDiscoveryPersistence()
        let dataProvider = ServiceDiscoveryDataProvider(service: service, persistence: persistence, completion: completion)
        sharedInstance = ServiceDiscovery(apiRootURL: apiRootURL, bearerToken: bearerToken, dataProvider: dataProvider)
    }

    init(apiRootURL: URL?, bearerToken: String?, dataProvider: DataProvidable) {
        self.apiRootURL = apiRootURL
        self.bearerToken = bearerToken
        self.dataProvider = dataProvider
    }

    private func halLinkForEntryRelationNamed(_ name: String) -> STHALLink? {
        return dataProvider.serviceDiscoveryResource?.links.link(forRelationNamed: name)
    }

    private func serviceDiscoveryOverlayForEntryRelationNamed(_ name: String) -> STURITemplate? {
        return dataProvider.serviceDiscoveryOverlay[name] as? STURITemplate
    }

    private func serviceDiscoveryUnderlayForEntryRelationNamed(_ name: String) -> STURITemplate? {
        return dataProvider.serviceDiscoveryUnderlay[name] as? STURITemplate
    }
}

extension ServiceDiscovery: ServiceDiscoveryOverlayConfigurable {

    public func setServiceDiscoveryOverlayEntryRelation(with name: String, uriTemplate: String) {
        dataProvider.updateOverlay(with: name, uriTemplate: uriTemplate)
    }

    public func removeServiceDiscoveryOverlayEntryRelation(with name: String) {
        dataProvider.removeOverlay(for: name)
    }
}

extension ServiceDiscovery: ServiceDiscoveryUnderlayConfigurable {

    public func setServiceDiscoveryUnderlayEntryRelation(with name: String, uriTemplate: String) {
        dataProvider.updateUnderlay(with: name, uriTemplate: uriTemplate)
    }

    public func removeServiceDiscoveryUnderlayEntryRelation(with name: String) {
        dataProvider.removeUnderlay(for: name)
    }
}

extension ServiceDiscovery: ServiceDiscoveryQueryable {

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

    public func urlForEntryRelationNamed(_ name: String, variables: [String: String]?) -> URL? {
        if let overlay = serviceDiscoveryOverlayForEntryRelationNamed(name) {
            return overlay.urlByExpanding(withVariables: variables)
        }

        if let link = halLinkForEntryRelationNamed(name) {
            return urlForHALLink(link, variables: variables)
        }

        if let underlay = serviceDiscoveryUnderlayForEntryRelationNamed(name) {
            return underlay.urlByExpanding(withVariables: variables)
        }
        return nil
    }
}

extension ServiceDiscovery: ServiceDiscoverySTHALResolvable {

    public func urlForHALLink(_ link: STHALLink, variables: [String: String]?) -> URL? {
        return link.url(withVariables: variables)
    }
}

extension ServiceDiscovery: ServiceDiscoveryRefreshable {

    public func refreshServiceDiscoveryIfNecessary(_ completion: @escaping ServiceDiscoveryCompletionBlock) {
        dataProvider.requestServiceDiscovery(completion)
    }
}

extension ServiceDiscovery {

    public static func shared() -> ServiceDiscovery {
        if let ourInstance = sharedInstance {
            return ourInstance
        }
        fatalError("shared instance invoked before instantiate")
    }
}
