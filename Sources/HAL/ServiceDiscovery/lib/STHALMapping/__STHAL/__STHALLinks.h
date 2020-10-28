//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import "__STHAL.h"

@interface __STHALLinks : NSObject<__STHALLinks>
+ (NSArray *)linksForRelationNamed:(NSString *)name inDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(__STHALResourceReadingOptions)options;
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(__STHALResourceReadingOptions)options;
- (NSDictionary *)dictionaryRepresentationWithOptions:(__STHALResourceWritingOptions)options;
@end
