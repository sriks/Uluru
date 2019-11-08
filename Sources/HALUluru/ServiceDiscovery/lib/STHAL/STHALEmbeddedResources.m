//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import "STHALEmbeddedResources.h"

#import "STHALTypeSafety.h"
#import "STHALResource.h"


@implementation STHALEmbeddedResources {
@private
    NSDictionary *_resources;
}

- (id)init {
    return [self initWithDictionary:nil baseURL:nil options:0];
}
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(STHALResourceReadingOptions)options {
    NSParameterAssert(dict);
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSParameterAssert(baseURL);
    if (!baseURL) {
        return nil;
    }

    if ((self = [super init])) {
        NSMutableDictionary * const resources = [[NSMutableDictionary alloc] initWithCapacity:dict.count];

        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL * __unused stop) {
            NSString * const resourceName = STHALEnsureNSString(key);
            if (!resourceName) {
                return;
            }

            NSMutableArray * const resourcesForName = [[NSMutableArray alloc] initWithCapacity:1];

            NSArray * const resourceObjects = STHALEnsureNSArray(obj);
            if (resourceObjects) {
                for (id resourceObject in resourceObjects) {
                    NSDictionary * const resourceDictionary = STHALEnsureNSDictionary(resourceObject);
                    if (resourceDictionary) {
                        id<STHALResource> const resource = [[STHALResource alloc] initWithDictionary:resourceDictionary baseURL:baseURL options:options];
                        if (resource) {
                            [resourcesForName addObject:resource];
                        }
                    }
                }
            } else {
                NSDictionary * const resourceDictionary = STHALEnsureNSDictionary(obj);
                if (resourceDictionary) {
                    id<STHALResource> const resource = [[STHALResource alloc] initWithDictionary:resourceDictionary baseURL:baseURL options:options];
                    if (resource) {
                        [resourcesForName addObject:resource];
                    }
                }
            }

            resources[resourceName] = resourcesForName.copy;
        }];

        _resources = resources.copy;
    }
    return self;
}

- (NSArray *)resourceNames {
    return [_resources.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

- (id<STHALResource>)resourceNamed:(NSString *)name {
    NSParameterAssert(name);
    if (!name) {
        return nil;
    }
    return STHALEnsureNSArray(_resources[name]).firstObject;
}
- (NSArray *)resourcesNamed:(NSString *)name {
    NSParameterAssert(name);
    if (!name) {
        return nil;
    }
    return  _resources[name];
}

- (id)objectForKeyedSubscript:(NSString *)name {
    NSParameterAssert(name);
    if (!name) {
        return nil;
    }
    NSArray * const resources = STHALEnsureNSArray(_resources[name]);
    if (resources.count == 1) {
        return resources.firstObject;
    }
    return resources;
}

- (NSDictionary *)dictionaryRepresentationWithOptions:(STHALResourceWritingOptions)options {
    NSMutableDictionary * const dictionary = [[NSMutableDictionary alloc] initWithCapacity:_resources.count];
    [_resources enumerateKeysAndObjectsUsingBlock:^(id<NSCopying> key, id obj, BOOL * __unused stop) {
        NSArray * const array = STHALEnsureNSArray(obj);
        if (array) {
            NSMutableArray * const embeddedDictionaries = [[NSMutableArray alloc] initWithCapacity:array.count];
            [array enumerateObjectsUsingBlock:^(id obj, NSUInteger __unused idx, BOOL * __unused stop) {
                NSDictionary * const embeddedDictionary = [obj dictionaryRepresentationWithOptions:options];
                if (embeddedDictionary) {
                    [embeddedDictionaries addObject:embeddedDictionary];
                }
            }];
            dictionary[key] = embeddedDictionaries;
        } else {
            NSDictionary * const embeddedDictionary = [obj dictionaryRepresentationWithOptions:options];
            if (embeddedDictionary) {
                dictionary[key] = embeddedDictionary;
            }
        }
    }];
    return dictionary.copy;
}

@end
