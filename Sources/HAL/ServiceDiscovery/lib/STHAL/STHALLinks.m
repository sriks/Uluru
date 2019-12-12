//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import "STHALLinks.h"
#import "STHALTypeSafety.h"
#import "STURITemplate.h"

@interface STHALLink : NSObject<STHALLink>
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(STHALResourceReadingOptions)options;
- (id)dictionaryRepresentationWithOptions:(STHALResourceWritingOptions)options;
@end


@implementation STHALLinks {
@private
    NSDictionary *_links;
}

+ (NSArray *)linksForRelationNamed:(NSString *)name inDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(STHALResourceReadingOptions)options {
    NSArray * __block links = nil;
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * __unused stop) {
        NSString * const relationName = STHALEnsureNSString(key);
        if (!relationName) {
            return;
        }
        if (![name isEqualToString:relationName]) {
            return;
        }

        links = [self linksFromLinkJSONObject:obj baseURL:baseURL options:options];
    }];
    return links;
}

+ (NSArray *)linksFromLinkJSONObject:(id)object baseURL:(NSURL *)baseURL options:(STHALResourceReadingOptions)options {
    NSMutableArray * const linksForName = [[NSMutableArray alloc] initWithCapacity:1];

    NSArray *linkObjects = STHALEnsureNSArray(object);
    if (!linkObjects && object) {
        linkObjects = @[ object ];
    }
    for (id linkObject in linkObjects) {
        NSDictionary * const linkDictionary = STHALEnsureNSDictionary(linkObject);
        if (linkDictionary) {
            id<STHALLink> const link = [[STHALLink alloc] initWithDictionary:linkDictionary baseURL:baseURL options:options];
            if (link) {
                [linksForName addObject:link];
            }
            continue;
        } else if (options & STHALResourceReadingAllowSimplifiedLinks) {
            NSString * const linkString = STHALEnsureNSString(linkObject);
            if (linkString) {
                NSDictionary * const linkDictionary = @{ @"href": linkString, @"templated": @YES };
                id<STHALLink> const link = [[STHALLink alloc] initWithDictionary:linkDictionary baseURL:baseURL options:options];
                if (link) {
                    [linksForName addObject:link];
                }
                continue;
            }
        }
    }

    return linksForName.copy;
}

- (id)init {
    return [self initWithDictionary:nil baseURL:nil options:0];
}
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(STHALResourceReadingOptions)options {
    NSParameterAssert(dict);
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    if ((self = [super init])) {
        NSMutableDictionary * const links = [[NSMutableDictionary alloc] initWithCapacity:dict.count];
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * __unused stop) {
            NSString * const relationName = STHALEnsureNSString(key);
            if (!relationName) {
                return;
            }

            NSArray * const linksForName = [self.class linksFromLinkJSONObject:obj baseURL:baseURL options:options];
            links[relationName] = linksForName ?: @[];
        }];
        _links = links.copy;
    }
    return self;
}


- (NSArray *)relationNames {
    return [_links.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

- (id<STHALLink>)linkForRelationNamed:(NSString *)name {
    return STHALEnsureNSArray(_links[name]).firstObject;
}
- (NSArray *)linksForRelationNamed:(NSString *)name {
    return STHALEnsureNSArray(_links[name]);
}

- (id)objectForKeyedSubscript:(NSString *)name {
    NSArray * const links = STHALEnsureNSArray(_links[name]);
    if (links.count <= 1) {
        return links.firstObject;
    }
    return links;
}

- (NSDictionary *)dictionaryRepresentationWithOptions:(STHALResourceWritingOptions)options {
    NSMutableDictionary * const dictionary = [[NSMutableDictionary alloc] initWithCapacity:_links.count];
    [_links enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSArray *links, BOOL * __unused stop) {
        NSMutableArray * const linkDictionaries = [[NSMutableArray alloc] init];
        [links enumerateObjectsUsingBlock:^(STHALLink *link, NSUInteger __unused idx, BOOL * __unused stop) {
            id const linkRepresentation = [link dictionaryRepresentationWithOptions:options];
            if (linkRepresentation) {
                [linkDictionaries addObject:linkRepresentation];
            }
        }];
        switch (linkDictionaries.count) {
            case 0:
                break;
            case 1:
                dictionary[name] = linkDictionaries.firstObject;
                break;
            default:
                dictionary[name] = linkDictionaries;
                break;
        }
    }];
    return dictionary.copy;
}

@end


@implementation STHALLink {
@private
    NSString *_href;
    STURITemplate *_template;
    NSURL *_baseURL;
}

- (id)init {
    return [self initWithDictionary:nil baseURL:nil options:0];
}
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(STHALResourceReadingOptions __unused)options {
    NSParameterAssert(dict);
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSString * const href = STHALEnsureNSString(dict[@"href"]);
    if (!href) {
        return nil;
    }

    if ((self = [super init])) {
        _name = STHALEnsureNSString(dict[@"name"]).copy;
        _type = STHALEnsureNSString(dict[@"type"]).copy;
        _href = href.copy;
        if (STHALEnsureNSNumber(dict[@"templated"]).boolValue) {
            _template = [[STURITemplate alloc] initWithString:_href];
        }
        _title = STHALEnsureNSString(dict[@"title"]).copy;
        _hreflang = STHALEnsureNSString(dict[@"hreflang"]).copy;
        _deprecation = STHALEnsureNSString(dict[@"deprecation"]).copy;
        _baseURL = baseURL.copy;
    }
    return self;
}

@synthesize name = _name;
@synthesize type = _type;
@dynamic url;
@synthesize deprecation = _deprecation;
@synthesize title = _title;
@synthesize hreflang = _hreflang;

- (NSArray *)templateVariableNames {
    return _template.variableNames ?: @[];
}

- (NSURL *)url {
    return [self urlWithVariables:nil];
}
- (NSURL *)urlWithVariables:(NSDictionary *)variables {
    if (_template) {
        NSString * const urlString = [_template stringByExpandingWithVariables:variables];
        return [NSURL URLWithString:urlString relativeToURL:_baseURL];
    }
    return [NSURL URLWithString:_href relativeToURL:_baseURL];
}

- (id)dictionaryRepresentationWithOptions:(STHALResourceWritingOptions)options {
    NSMutableDictionary * const dictionary = [[NSMutableDictionary alloc] init];
    if (_name) {
        dictionary[@"name"] = _name;
    }
    if (_title) {
        dictionary[@"title"] = _title;
    }
    if (_type) {
        dictionary[@"type"] = _type;
    }
    dictionary[@"href"] = _href;
    if (_hreflang) {
        dictionary[@"hreflang"] = _hreflang;
    }
    if (_deprecation) {
        dictionary[@"deprecation"] = _deprecation;
    }

    if (options & STHALResourceWritingWriteSimplifiedLinks) {
        if ([@[ @"href" ] isEqualToArray:dictionary.allKeys]) {
            return dictionary[@"href"];
        }
    }
    if (_template) {
        dictionary[@"templated"] = @YES;
    }

    return dictionary.copy;
}

@end
