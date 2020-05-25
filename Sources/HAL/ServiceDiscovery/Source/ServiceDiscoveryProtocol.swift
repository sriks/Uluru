//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public protocol ServiceDiscoveryOverlayConfigurable {
    func setServiceDiscoveryOverlayEntryRelation(with name: String, uriTemplate: String)
    func removeServiceDiscoveryOverlayEntryRelation(with name: String)
}

public protocol ServiceDiscoveryUnderlayConfigurable {
    func setServiceDiscoveryUnderlayEntryRelation(with name: String, uriTemplate: String)
    func removeServiceDiscoveryUnderlayEntryRelation(with name: String)
}

public protocol ServiceDiscoveryRefreshable {
    func refreshServiceDiscoveryIfNecessary(_ completion: @escaping ServiceDiscoveryCompletionBlock)
}

public protocol ServiceDiscoveryPredefinedUrlVariableUpdatable {
    func updateVariable(forName name: String, withValue value: String)
}

@objc
public protocol ServiceDiscoveryQueryable {
    @objc func hasURLForEntryRelationNamed(_ name: String) -> Bool
    @objc func urlVariableNamesForEntryRelationNamed(_ name: String) -> [String]?
    @objc func urlForEntryRelationNamed(_ name: String, variables: [String: Any]?) -> URL?
}

public protocol ServiceDiscovery__STHALResolvable: ServiceDiscoveryQueryable {
    func urlForHALLink(_ link: __STHALLink, variables: [String: Any]?) -> URL?
}

/// Service Discovery capability
public typealias ServiceDiscoveryType = ServiceDiscoveryOverlayConfigurable & ServiceDiscoveryUnderlayConfigurable & ServiceDiscoveryRefreshable & ServiceDiscovery__STHALResolvable
