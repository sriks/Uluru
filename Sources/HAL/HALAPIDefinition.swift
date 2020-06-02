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

// Ability to resolve a URI Entity
public protocol URIEntityResolvable {
    // Returns a fully resolved URL. This can be nil to indicate failure.
    func resolved() -> URL?
}

/// URI Entity which can be resolved into a fully formed URL.
/// This can be used in two mutually exlusive ways
/// * Creates an instance with a template URI and variables
///     * The variables are filled into the URI before resolving to an URL.
///     * For ex: `https://api.com/v1/accounts/{accountNumber}/transactions{?count}`
///
/// * Creates an instance with an URL.
///     * The supplied URL is used as is.
public struct URIEntity: URIEntityResolvable {
    public let urlString: String
    public let variables: Uluru.JSONRepresentable?

    init(_ uriTemplate: String, variables: Uluru.JSONRepresentable? = nil) {
        urlString = uriTemplate
        self.variables = variables
    }

    init(_ url: URL) {
        urlString = url.absoluteString
        variables = nil
    }
}

/// The type of entity resolution
public enum EntityResolution {
    /// Resolve with a named entity and optional params
    case namedEntity(NamedEntity)

    /// Resolve with a URI and optional params
    case linkedEntity(URIEntity)
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


