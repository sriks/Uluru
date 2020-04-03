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

/// HAL Entity resolved by URL
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
    /// Resolve with a named entity and optional params
    case namedEntity(NamedEntity)

    /// Resolve with a HAL link and optional params
    case linkedEntity(LinkedEntity)
}

/// A conformance protocol that expresses that APIDefinition requires HAL entity resolution.
public protocol RequiresHALEntityResolution {

    /// The HAL entity resolution strategy
    var entityResolution: EntityResolution { get }
}

/// Provides HAL based APIDefinition. Use this when you need HAL entity resolution to make API calls.
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


