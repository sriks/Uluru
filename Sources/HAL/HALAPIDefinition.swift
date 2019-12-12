//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

/// HAL Entity resolved by name
public struct NamedEntity {
    public let name: String
    public let variables: Uluru.JSONRepresentable?

    public init(name: String, variables: Uluru.JSONRepresentable? = nil) {
        self.name = name
        self.variables = variables
    }
}

/// HAL Entity resolved by URL.
public struct LinkedEntity {
    public let halLink: STHALLink
    public let variables: Uluru.JSONRepresentable?

    public init(halLink: STHALLink, variables: Uluru.JSONRepresentable? = nil) {
        self.halLink = halLink
        self.variables = variables
    }
}

/// The type of entity resolution
public enum EntityResolution {
    case namedEntity(NamedEntity)
    case linkedEntity(LinkedEntity)
}

/// A conformance protocol that expresses the type of HAL entity resolution.
public protocol RequiresHALEntityResolution {
    var entityResolution: EntityResolution { get }
}

/// Provides HAL based APIDefinition
public protocol HALAPIDefinition: APIDefinition, RequiresHALEntityResolution {}

public extension HALAPIDefinition {

    var baseURL: URL {
        return URL(string: "hal://")!
    }

    var path: String {
        return "entity"
    }

    var placeholderData: Data? {
        return nil
    }

    var headers: [String : String]? {
        return nil
    }
}


