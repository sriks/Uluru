//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import <Foundation/Foundation.h>

#ifndef __STHAL___STHALTypeSafety_h
#define __STHAL___STHALTypeSafety_h


#define __STHALDeclareEnsure(type) \
static inline type *__STHALEnsure##type(id o) { \
    if ([o isKindOfClass:[type class]]) { \
        return o; \
    } \
    return nil; \
}

__STHALDeclareEnsure(NSArray)
__STHALDeclareEnsure(NSDictionary)
__STHALDeclareEnsure(NSNumber)
__STHALDeclareEnsure(NSString)

#undef __STHALDeclareEnsure

#endif
