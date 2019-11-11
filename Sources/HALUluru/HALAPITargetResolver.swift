//Copyright © 2019 Tabcorp. All rights reserved.

import Foundation
#if !COCOAPODS
import Uluru
#endif

public extension ServiceRequester {

    /// Provides target resolver which resolves an APIDefintion to an APITarget with fully formed URL using HAL entity resolution.
    static func makeHALTargetResolver() -> APITargetResolver {
        let resolver: APITargetResolver = { apiDef in
            guard let halAPI = apiDef as? RequiresHALEntityResolution else {
                return .failure(.invalidResolvedUrl(apiDef.baseURL))
            }

            // TODO: once service discovery accepts [String: Any] then remove the casting.
            let url: URL? = {
                switch halAPI.entityResolution {
                case .namedEntity(let named):
                    return ServiceDiscovery.shared().urlForEntryRelationNamed(named.name,
                                                                              variables: try? named.variables?.jsonObject() as? [String : String])
                case .linkedEntity(let linked):
                    return ServiceDiscovery.shared().urlForHALLink(linked.halLink,
                                                                   variables: try? linked.variables?.jsonObject() as? [String : String])
                }
            }()

            guard let resolvedURL = url else {
                return .failure(.invalidResolvedUrl(apiDef.baseURL))
            }

            let target = APITarget.makeFrom(apiDef, resolvedURL: resolvedURL)
            return .success(target)
        }
        return resolver
    }
}
