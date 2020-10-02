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

    private let fileURL: URL

    var shouldLoadFromFile: Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: fileURL.path)
    }

    init(fileURL: URL?) {
        if let url = fileURL,
            url.scheme == Constant.fileScheme {
            // We use local file URL for unit testing
            self.fileURL = url
        } else {
            var url = FileManager.default.cachesDirectoryURL
            // use apiRootURL host as the sub directory
            // so each envrionment could have its own discovery cache
            // the url would be like:
            // cachesDir/api.beta.tab.com.au/discovery.json
            if let subDir = fileURL?.host {
                url = url.appendingPathComponent(subDir, isDirectory: true)
            }
            self.fileURL = url.appendingPathComponent(Constant.discoveryStorageFileName)
        }
    }

    func loadServiceDiscoveryFromPersistence(_ completion: (__STHALResource?, Error?) -> Void) {
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
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
                try discoveryData.write(to: fileURL, options: .completeFileProtection)
                completion?(true, nil)
            }
        } catch (let error) {
            completion?(false, error)
        }
    }
}

private extension FileManager {
    var cachesDirectoryURL: URL {
        let paths = urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }
}
