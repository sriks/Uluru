//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

protocol ServiceDiscoveryPersistentable {
    var shouldLoadFromFile: Bool { get }

    func loadServiceDiscoveryFromPersistence(_ completion: (STHALResource?, Error?)-> Void)
    func saveServiceDiscoveryToPersistence(resource: STHALResource, completion: ((Bool, Error?)-> Void)?)
}

class ServiceDiscoveryPersistence: ServiceDiscoveryPersistentable {

    private enum Constant {
        static let discoveryStorageFileName = "discovery.json"
    }

    private let fileURL: URL?

    var shouldLoadFromFile: Bool {
        return isExternalFileURL
    }

    init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    func loadServiceDiscoveryFromPersistence(_ completion: (STHALResource?, Error?) -> Void) {
        do {
            let data = try Data(contentsOf: serviceDiscoveryURL, options: .mappedIfSafe)
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
        do {
            if let dict = resource.dictionaryRepresentation(options: .writeSimplifiedLinks) {
                let discoveryData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
                try discoveryData.write(to: serviceDiscoveryURL, options: .completeFileProtection)
                completion?(true, nil)
            }
        } catch (let error) {
            completion?(false, error)
        }
    }
}

private extension ServiceDiscoveryPersistence {

    var discoveryDefaultStorageURL: URL {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(Constant.discoveryStorageFileName, isDirectory: false)
    }

    var isExternalFileURL: Bool {
        guard let fileURL = fileURL else { return false }

        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: fileURL.absoluteString)
    }

    var serviceDiscoveryURL: URL {
        return isExternalFileURL ? fileURL! : discoveryDefaultStorageURL
    }
}
