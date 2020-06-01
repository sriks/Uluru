//Copyright © 2020 Tabcorp. All rights reserved.

import Foundation

// MARK: URIEntityResolvable
extension URIEntity {
    public func resolved() -> URL? {
        guard let ourVariables = variables else { return URL(string: urlString) }
        let halLink = HALLinkRepresentation(template: __STURITemplate(string: urlString))
        return halLink.url(withVariables: try? ourVariables.jsonObject())
    }
}

// MARK: Implementation Detail

/// This is a swift wrapper to massage to STHALLink. Not intended for public.
class HALLinkRepresentation: NSObject, __STHALLink {

    private let template: (__STURITemplate & __STURITemplateProtocol)?
    private let href: String?
    private let baseURL: URL?

    // STHALLink
    let name: String?
    let title: String?
    let type: String?
    let hreflang: String?
    let templateVariableNames: [Any]
    lazy var url: URL? = { self.url(withVariables: nil) }()
    let deprecation: URL?

    init(href: String? = nil,
         baseURL: URL? = nil,
         template: (__STURITemplate & __STURITemplateProtocol)? = nil,
         name: String? = nil,
         title: String? = nil,
         type: String? = nil,
         hreflang: String? = nil,
         templateVariableNames: [Any] = [],
         deprecation: URL? = nil) {
        self.href = href
        self.baseURL = baseURL
        self.template = template
        self.name = name
        self.title = title
        self.type = type
        self.hreflang = hreflang
        self.templateVariableNames = templateVariableNames
        self.deprecation = deprecation
    }

    func url(withVariables variables: [AnyHashable: Any]?) -> URL? {
        guard let template = template, let urlString = template.stringByExpanding(withVariables: variables) else {
            guard let href = href else { return nil }
            return URL(string: href, relativeTo: baseURL)
        }
        return URL(string: urlString, relativeTo: baseURL)
    }
}
