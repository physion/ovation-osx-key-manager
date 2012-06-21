//
//  OVKeyManagerHelperAPI.m
//  OVKeyManager
//
//  Created by Barry Wark on 6/20/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#include <syslog.h>

#import "OVKeyManagerHelperAPI.h"
#import "PHCErrors.h"


const char * COMMAND_KEY = "ovation-command-key";
const char * INSTITUTION_KEY = "ovation-institution-key";
const char * GROUP_KEY = "ovation-group-key";
const char * PRODUCT_KEY = "ovation-product-key";

const char * KEY_ID_KEY = "ovation-key-id-key";
const char * SHARED_ENCRYPTION_KEY_KEY = "ovation-shared-encryption-key-key";

const char * RESULT_STATUS_KEY = "ovation-result-status-key";
const char * RESULT_ERR_MSG_KEY = "ovation-result-err-msg-key";

const char * ADD_KEY_COMMAND = "ovation-add-key-command";

BOOL writeKey(const char * service, const char * keyID, const char * key, NSError * __autoreleasing *err)
{
	SecKeychainItemRef item = nil;
    UInt32 passwordLength;
    void *passwordData;
    
    BOOL existingItem = YES;
	OSStatus returnStatus = SecKeychainFindGenericPassword(NULL, 
                                                           strlen(service),
                                                           service, 
                                                           strlen(keyID), 
                                                           keyID, 
                                                           &passwordLength, 
                                                           &passwordData, 
                                                           &item);
    
    if(returnStatus == errSecItemNotFound) {
        existingItem = NO;
        returnStatus = SecKeychainAddGenericPassword(NULL,
                                                     strlen(service), //service
                                                     service, 
                                                     strlen(keyID),
                                                     keyID, //username 
                                                     strlen(key), 
                                                     key, //password
                                                     &item);
    }
	
	if (returnStatus != errSecSuccess || !item) {
		NSString *errMsg = (NSString*)CFBridgingRelease(SecCopyErrorMessageString(returnStatus, NULL));
		
		if(item != NULL) {
			CFRelease(item);
		}
		
        if(*err != NULL) {
            *err = [NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN 
                                       code:KEYCHAIN_ERROR
                                   userInfo:[NSDictionary dictionaryWithObject:errMsg
                                                                        forKey:NSLocalizedDescriptionKey]];
        }
		
		return NO;
	}
    
    if(existingItem) { //Update password
       
        returnStatus = SecKeychainItemModifyAttributesAndData (
                                                         item,         // the item reference
                                                         NULL,            // no change to attributes
                                                         strlen(key),  // length of password
                                                         key         // pointer to password data
                                                         );
        
        
    } else {
        
        // set item kind to "Ovation Database Key"
        const char *description = "Ovation Database Encryption Key";
        SecKeychainAttribute kindAttr;
        kindAttr.tag = kSecDescriptionItemAttr;
        kindAttr.length = (UInt32)strlen(description);
        kindAttr.data = (void*)description;
        
        SecKeychainAttributeList attrs;
        attrs.count = 1;
        attrs.attr = &kindAttr;
        
        returnStatus = SecKeychainItemModifyAttributesAndData(item, &attrs, 0, NULL);
    }
    
    
    if(returnStatus != errSecSuccess) {
        NSString *errMsg = (NSString*)CFBridgingRelease(SecCopyErrorMessageString(returnStatus, NULL));
        
        if(item != NULL) {
            CFRelease(item);
        }
        
        if(*err != NULL) {
            *err = [NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN 
                                       code:KEYCHAIN_ERROR
                                   userInfo:[NSDictionary dictionaryWithObject:errMsg
                                                                        forKey:NSLocalizedDescriptionKey]];
        }
        
        return NO;
    }
	
	return YES;
}