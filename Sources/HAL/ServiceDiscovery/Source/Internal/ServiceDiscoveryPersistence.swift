//  Copyright © 2019 Tabcorp. All rights reserved.

import Foundation

protocol ServiceDiscoveryPersistentable {
    var shouldLoadFromFile: Bool { get }

    func loadServiceDiscoveryFromPersistence(_ completion: (__STHALResource?, Error?)-> Void)
    func saveServiceDiscoveryToPersistence(resource: __STHALResource, completion: ((Bool, Error?)-> Void)?)
}

class ServiceDiscoveryPersistence: ServiceDiscoveryPersistentable {

    private enum Constant {
        static let discoveryStorageFileName = "discovery.json"
        static let fileScheme = "file"
    }

    private let fileURL: URL?

    var shouldLoadFromFile: Bool {
        return isExternalFileExist
    }

    init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    func loadServiceDiscoveryFromPersistence(_ completion: (__STHALResource?, Error?) -> Void) {
        do {
            let data = try Data(contentsOf: try serviceDiscoveryURL(), options: .mappedIfSafe)
            if let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String : Any] {
                let serviceDiscoveryResource = __STHALResource(dictionary: jsonObj, baseURL: nil, options: __STHALResourceReadingOptions.allowSimplifiedLinks)
                completion(serviceDiscoveryResource, nil)
                return
            }
        } catch (let error) {
            completion(nil, error)
            return
        }
    }

    func saveServiceDiscoveryToPersistence(resource: __STHALResource, completion: ((Bool, Error?)-> Void)?) {
        do {
            if let dict = resource.dictionaryRepresentation(options: .writeSimplifiedLinks) {
                let discoveryData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
                try discoveryData.write(to: try serviceDiscoveryURL(), options: .completeFileProtection)
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

    var isExternalFileExist: Bool {
        guard let fileURL = fileURL,
              fileURL.scheme == Constant.fileScheme else { return false }

        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: fileURL.path)
    }

    var isSavedTemplateExist: Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: discoveryDefaultStorageURL.path)
    }

    func serviceDiscoveryURL() throws -> URL {
        if let fileURL = fileURL, isExternalFileExist {
            return fileURL // loading from file
        } else if isSavedTemplateExist {
            return discoveryDefaultStorageURL // loading from saved template(fallback action of loading from API)
        } else {
            throw DiscoveryError.fileNotFound // loading from file but file not found
        }
    }
}
