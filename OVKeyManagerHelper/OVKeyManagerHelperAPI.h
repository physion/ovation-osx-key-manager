//
//  OVKeyManagerHelperAPI.h
//  OVKeyManager
//
//  Created by Barry Wark on 6/20/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT const char * COMMAND_KEY;
FOUNDATION_EXPORT const char * INSTITUTION_KEY;
FOUNDATION_EXPORT const char * GROUP_KEY;
FOUNDATION_EXPORT const char * PRODUCT_KEY;
FOUNDATION_EXPORT const char * SHARED_ENCRYPTION_KEY_KEY;
FOUNDATION_EXPORT const char * KEY_ID_KEY;

FOUNDATION_EXPORT const char * ADD_KEY_COMMAND;

FOUNDATION_EXPORT const char * RESULT_STATUS_KEY;
FOUNDATION_EXPORT const char * RESULT_ERR_MSG_KEY;

FOUNDATION_EXPORT BOOL writeKey(const char * service, const char * keyID, const char * key, NSError * __autoreleasing *err);
