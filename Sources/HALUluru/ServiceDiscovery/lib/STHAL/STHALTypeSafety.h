//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import <Foundation/Foundation.h>

#ifndef STHAL_STHALTypeSafety_h
#define STHAL_STHALTypeSafety_h


#define STHALDeclareEnsure(type) \
static inline type *STHALEnsure##type(id o) { \
    if ([o isKindOfClass:[type class]]) { \
        return o; \
    } \
    return nil; \
}

STHALDeclareEnsure(NSArray)
STHALDeclareEnsure(NSDictionary)
STHALDeclareEnsure(NSNumber)
STHALDeclareEnsure(NSString)

#undef STHALDeclareEnsure

#endif
