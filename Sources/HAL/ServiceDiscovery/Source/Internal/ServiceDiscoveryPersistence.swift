//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

protocol ServiceDiscoveryPersistentable {
    func loadServiceDiscoveryFromPersistence(_ completion: (STHALResource?, Error?)-> Void)
    func saveServiceDiscoveryToPersistence(resource: STHALResource, completion: ((Bool, Error?)-> Void)?)
}

class ServiceDiscoveryPersistence: ServiceDiscoveryPersistentable {

    private enum Constant {
        static let discoveryStorageFileName = "discovery.json"
    }

    func loadServiceDiscoveryFromPersistence(_ completion: (STHALResource?, Error?) -> Void) {
        let fileURL = discoveryStorageURL()

        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            if let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String : Any] {
                let serviceDiscoveryResource = STHALResource(dictionary: jsonObj, baseURL: nil, options: STHALResourceReadingOptions.allowSimplifiedLinks)
                completion(serviceDiscoveryResource, nil)
                return
            }
        } catch (let error) {
            completion(nil, error)
            return
        }
    }

    func saveServiceDiscoveryToPersistence(resource: STHALResource, completion: ((Bool, Error?)-> Void)?) {
        let fileURL = discoveryStorageURL()

        do {
            if let dict = resource.dictionaryRepresentation(options: .writeSimplifiedLinks) {
                let discoveryData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
                try discoveryData.write(to: fileURL, options: .completeFileProtection)
                completion?(true, nil)
            }
        } catch (let error) {
            completion?(false, error)
        }
    }
}

private extension ServiceDiscoveryPersistence {

    func discoveryStorageURL() -> URL {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(Constant.discoveryStorageFileName, isDirectory: false)
    }
}
