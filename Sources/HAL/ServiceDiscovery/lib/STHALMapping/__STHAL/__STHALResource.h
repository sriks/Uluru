//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import <Foundation/Foundation.h>


@protocol __STHALLinks;
@protocol __STHALEmbeddedResources;
@protocol __STHALResource <NSObject>
@property (nonatomic,strong,readonly) id<__STHALLinks> links;
@property (nonatomic,copy,readonly) NSDictionary *payload;
@property (nonatomic,strong,readonly) id<__STHALEmbeddedResources> embeddedResources;
@end

@protocol __STHALLink;
@protocol __STHALLinks <NSObject>
@property (nonatomic,copy,readonly) NSArray *relationNames;
- (id<__STHALLink>)linkForRelationNamed:(NSString *)name;
- (NSArray *)linksForRelationNamed:(NSString *)name;
- (id)objectForKeyedSubscript:(NSString *)name;
@end

@protocol __STHALLink <NSObject>
@property (nonatomic,copy,readonly) NSString *name;
@property (nonatomic,copy,readonly) NSString *title;
@property (nonatomic,copy,readonly) NSString *type;
@property (nonatomic,copy,readonly) NSString *hreflang;
@property (nonatomic,copy,readonly) NSArray *templateVariableNames;
@property (nonatomic,copy,readonly) NSURL *url;
- (NSURL *)urlWithVariables:(NSDictionary *)variables;
@property (nonatomic,copy,readonly) NSURL *deprecation;
@end

@protocol __STHALEmbeddedResources <NSObject>
@property (nonatomic,copy,readonly) NSArray *resourceNames;
- (id<__STHALResource>)resourceNamed:(NSString *)name;
- (NSArray *)resourcesNamed:(NSString *)name;
- (id)objectForKeyedSubscript:(NSString *)name;
@end


typedef NS_OPTIONS(NSUInteger, __STHALResourceReadingOptions) {
    __STHALResourceReadingOptionsNone = 0,
    __STHALResourceReadingAllowSimplifiedLinks = 0x1,
    __STHALResourceReadingInferBaseURL = 0x2,
};

typedef NS_OPTIONS(NSUInteger, __STHALResourceWritingOptions) {
    __STHALResourceWritingOptionsNone = 0,
    __STHALResourceWritingWriteSimplifiedLinks = 0x1,
};

@interface __STHALResource : NSObject<__STHALResource>
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL;
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(__STHALResourceReadingOptions)options;
@property (nonatomic,strong,readonly) id<__STHALLinks> links;
@property (nonatomic,copy,readonly) NSDictionary *payload;
@property (nonatomic,strong,readonly) id<__STHALEmbeddedResources> embeddedResources;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)dictionaryRepresentationWithOptions:(__STHALResourceWritingOptions)options;
@end
