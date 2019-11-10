//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
import Uluru

/// HAL Entity resolved by name
public struct NamedEntity {
    let name: String
    let variables: Uluru.JSONRepresentable?
}

/// HAL Entity resolved by URL.
public struct LinkedEntity {
    let halLink: STHALLink
    let variables: Uluru.JSONRepresentable?
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

extension HALAPIDefinition {

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


