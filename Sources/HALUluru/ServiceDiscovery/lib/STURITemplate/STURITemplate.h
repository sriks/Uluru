//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import <Foundation/Foundation.h>


extern NSString * const STURITemplateErrorDomain;


@protocol STURITemplate <NSObject>
@property (nonatomic,copy,readonly) NSArray *variableNames;
- (NSString *)stringByExpandingWithVariables:(NSDictionary *)variables;
- (NSURL *)urlByExpandingWithVariables:(NSDictionary *)variables;
@end

@interface STURITemplate : NSObject<STURITemplate>
- (id)initWithString:(NSString *)string;
- (id)initWithString:(NSString *)string error:(NSError * __autoreleasing *)error;
- (NSString *)templatedStringRepresentation;
@end
