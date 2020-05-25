//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import "__STHALResource.h"
#import "__STHALTypeSafety.h"
#import "__STHALLinks.h"
#import "__STHALEmbeddedResources.h"

@implementation __STHALResource {
@private
    __STHALLinks *_links;
    NSDictionary *_payload;
    __STHALEmbeddedResources *_embedded;
}

- (id)init {
    return [self initWithDictionary:nil baseURL:nil options:0];
}
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL {
    return [self initWithDictionary:dict baseURL:baseURL options:0];
}
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(__STHALResourceReadingOptions)options {
    NSParameterAssert(dict);
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSMutableDictionary * const payload = [[NSMutableDictionary alloc] initWithDictionary:dict];
    NSDictionary * const linksDictionary = __STHALEnsureNSDictionary(payload[@"_links"]);
    NSDictionary * const embeddedResourceDictionary = __STHALEnsureNSDictionary(payload[@"_embedded"]);

    if (options & __STHALResourceReadingInferBaseURL) {
        if (!baseURL) {
            NSArray * const selfLinks = [__STHALLinks linksForRelationNamed:@"self" inDictionary:linksDictionary baseURL:nil options:options];
            id<__STHALLink> const selfLink = selfLinks.firstObject;
            if (selfLink) {
                baseURL = selfLink.url;
            }
        }
    }

    if ((self = [super init])) {
        if (linksDictionary) {
            if ((_links = [[__STHALLinks alloc] initWithDictionary:linksDictionary baseURL:baseURL options:options])) {
                [payload removeObjectForKey:@"_links"];
            }
        }

        if (embeddedResourceDictionary) {
            if ((_embedded = [[__STHALEmbeddedResources alloc] initWithDictionary:embeddedResourceDictionary baseURL:baseURL options:options])) {
                [payload removeObjectForKey:@"_embedded"];
            }
        }

        _payload = payload.copy;
    }
    return self;
}


@synthesize links = _links;
@synthesize payload = _payload;
@synthesize embeddedResources = _embedded;


- (NSDictionary *)dictionaryRepresentation {
    return [self dictionaryRepresentationWithOptions:__STHALResourceWritingOptionsNone];
}
- (NSDictionary *)dictionaryRepresentationWithOptions:(__STHALResourceWritingOptions)options {
    NSMutableDictionary * const dictionary = [[NSMutableDictionary alloc] initWithDictionary:_payload];
    NSDictionary * const linksDictionary = [_links dictionaryRepresentationWithOptions:options];
    if (linksDictionary) {
        dictionary[@"_links"] = linksDictionary;
    }
    NSDictionary * const embeddedResourcesDictionary = [_embedded dictionaryRepresentationWithOptions:options];
    if (embeddedResourcesDictionary) {
        dictionary[@"_embedded"] = embeddedResourcesDictionary;
    }
    return dictionary;
}

@end
