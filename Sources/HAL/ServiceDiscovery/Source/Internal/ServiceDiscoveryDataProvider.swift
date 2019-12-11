//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

protocol DataProvidable {
    var serviceDiscoveryResource: STHALResource? { get }
    var serviceDiscoveryLastUpdatedDate: Date? { get }
    var serviceDiscoveryOverlay: [String : Any] { get }
    var serviceDiscoveryUnderlay: [String : Any] { get }

    func updateOverlay(with name: String, uriTemplate: String)
    func removeOverlay(for name: String)
    func updateUnderlay(with name: String, uriTemplate: String)
    func removeUnderlay(for name: String)
    func requestServiceDiscovery(_ completion: ServiceDiscoveryCompletionBlock?)
}

class ServiceDiscoveryDataProvider: DataProvidable {

    var serviceDiscoveryResource: STHALResource?
    var serviceDiscoveryLastUpdatedDate: Date?
    var serviceDiscoveryOverlay: [String : Any] = [:]
    var serviceDiscoveryUnderlay: [String : Any] = [:]

    private let service: ServiceDiscoveryRequestable
    private let persistence: ServiceDiscoveryPersistentable
    private let completion: ServiceDiscoveryCompletionBlock?

    init(service: ServiceDiscoveryRequestable, persistence: ServiceDiscoveryPersistentable, completion: ServiceDiscoveryCompletionBlock?) {
        self.service = service
        self.persistence = persistence
        self.completion = completion
        loadDiscoveryResources(from: isLocalServiceDiscoveryDated() ? .server : .localStorage)
    }

    func updateOverlay(with name: String, uriTemplate: String) {
        guard let template = STURITemplate(string: uriTemplate) else {
            return
        }
        serviceDiscoveryOverlay[name] = template
    }

    func removeOverlay(for name: String) {
        serviceDiscoveryOverlay.removeValue(forKey: name)
    }

    func updateUnderlay(with name: String, uriTemplate: String) {
        guard let template = STURITemplate(string: uriTemplate) else {
            return
        }
        serviceDiscoveryUnderlay[name] = template
    }

    func removeUnderlay(for name: String) {
        serviceDiscoveryUnderlay.removeValue(forKey: name)
    }

    func requestServiceDiscovery(_ completion: ServiceDiscoveryCompletionBlock?) {
        if isServiceDiscoveryJustUpdated() {
            completion?(.failure(.discoveryIsUpToDate))
        }

        service.requestServiceDiscovery { [weak self] (apiRootURL, data, error) in
            guard let self = self else { return }

            guard let data = data else {
                completion?(.failure(.urlLoadingFailed))
                return
            }
            let result = self.processData(apiRootURL, data)
            completion?(result)
        }
    }
}

private extension ServiceDiscoveryDataProvider {

    enum ResourceLocation {
        case localStorage
        case server
    }

    func isServiceDiscoveryJustUpdated() -> Bool {
        guard let serviceDiscoveryLastUpdatedDate = serviceDiscoveryLastUpdatedDate else {
            return false
        }
        let serviceDiscoveryAge = -serviceDiscoveryLastUpdatedDate.timeIntervalSinceNow
        let fiveMinsTimeInterval: TimeInterval = 5 * 60
        if serviceDiscoveryAge >= 0 && serviceDiscoveryAge < fiveMinsTimeInterval {
            return true
        }
        return false
    }

    func isLocalServiceDiscoveryDated() -> Bool {
        guard let serviceDiscoveryLastUpdatedDate = serviceDiscoveryLastUpdatedDate else {
            return true
        }
        let serviceDiscoveryAge = abs(serviceDiscoveryLastUpdatedDate.timeIntervalSinceNow)
        let thirtyMinsTimeInterval: TimeInterval = 30 * 60
        return serviceDiscoveryAge > thirtyMinsTimeInterval
    }

    func processData(_ apiRootURL: URL?, _ data: Data) -> Result<Void, DiscoveryError> {
        do {
            if let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String : Any],
               let serviceDiscoveryResource = STHALResource(dictionary: jsonObj, baseURL: apiRootURL, options: STHALResourceReadingOptions.allowSimplifiedLinks) {
                updateServiceDiscovery(with: serviceDiscoveryResource)
                persistence.saveServiceDiscoveryToPersistence(resource: serviceDiscoveryResource, completion: nil)
                return .success
            } else {
                return .failure(.parsingFailed)
            }
        } catch {
            return .failure(.parsingFailed)
        }
    }

    func loadDiscoveryResources(from resourceLocation: ResourceLocation) {
        switch resourceLocation {
        case .localStorage:
            persistence.loadServiceDiscoveryFromPersistence { [weak self] (resources, error) in
                if let resources = resources {
                    self?.updateServiceDiscovery(with: resources)
                    completion?(.success)
                }
                self?.loadDiscoveryResources(from: .server)
            }
        case .server:
            requestServiceDiscovery(completion)
        }
    }

    func updateServiceDiscovery(with resources: STHALResource) {
        serviceDiscoveryResource = resources
        serviceDiscoveryLastUpdatedDate = Date()
    }
}
