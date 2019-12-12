//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import "STHAL.h"

@interface STHALLinks : NSObject<STHALLinks>
+ (NSArray *)linksForRelationNamed:(NSString *)name inDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(STHALResourceReadingOptions)options;
- (id)initWithDictionary:(NSDictionary *)dict baseURL:(NSURL *)baseURL options:(STHALResourceReadingOptions)options;
- (NSDictionary *)dictionaryRepresentationWithOptions:(STHALResourceWritingOptions)options;
@end
