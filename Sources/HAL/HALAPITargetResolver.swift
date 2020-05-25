//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

public extension ServiceRequester {

    /// Provides target resolver which resolves an APIDefintion to an APITarget with fully formed URL using HAL entity resolution.
    static func makeHALTargetResolver(_ serviceDiscovery: ServiceDiscoveryQueryable & ServiceDiscovery__STHALResolvable = ServiceDiscovery.shared()) -> APITargetResolver {
        let resolver: APITargetResolver = { apiDef in
            guard let halAPI = apiDef as? RequiresHALEntityResolution else {
                return .failure(.invalidResolvedUrl(apiDef.baseURL))
            }

            var entityName: String?
            let url: URL? = {
                switch halAPI.entityResolution {
                case .namedEntity(let named):
                    entityName = named.name
                    return serviceDiscovery.urlForEntryRelationNamed(named.name,
                                                                              variables: try? named.variables?.jsonObject())
                case .linkedEntity(let linked):
                    entityName = linked.halLink.name
                    return serviceDiscovery.urlForHALLink(linked.halLink,
                                                                   variables: try? linked.variables?.jsonObject())
                }
            }()

            guard let resolvedURL = url else {
                return .failure(.halEntityNotFound(entityName ?? "unknownEntity"))
            }

            let target = APITarget.makeFrom(apiDef, resolvedURL: resolvedURL)
            return .success(target)
        }
        return resolver
    }
}
