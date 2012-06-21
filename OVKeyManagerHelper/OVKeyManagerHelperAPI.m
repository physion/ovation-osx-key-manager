//
//  OVKeyManagerHelperAPI.m
//  OVKeyManager
//
//  Created by Barry Wark on 6/20/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#include <syslog.h>
#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>
#include <Security/SecAccess.h>
#include <Security/SecTrustedApplication.h>
#include <Security/SecACL.h>

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


BOOL handle_sec_error(OSStatus returnStatus, NSError **error)
{
    NSString *errMsg = (NSString*)CFBridgingRelease(SecCopyErrorMessageString(returnStatus, NULL));
    if(error != NULL) {
        *error = [NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN 
                                     code:KEYCHAIN_ERROR
                                 userInfo:[NSDictionary dictionaryWithObject:errMsg
                                                                      forKey:NSLocalizedDescriptionKey]];
    }
    
    return NO;
}

BOOL createAccess(NSString *accessLabel, NSArray *appPaths, SecAccessRef *access, NSError **error)
{
    OSStatus err;
    
    //Make an exception list of trusted applications; that is,
    // applications that are allowed to access the item without
    // requiring user confirmation:
    SecTrustedApplicationRef myself;
    
    //Create trusted application references; see SecTrustedApplications.h:
    err = SecTrustedApplicationCreateFromPath(NULL, &myself);
    if(err != errSecSuccess) {
        return handle_sec_error(err, error);
    }
    
    NSMutableArray *trustedApplications = [NSMutableArray arrayWithObject:(__bridge_transfer id)myself];
    
    BOOL __block failure = NO;
    [appPaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SecTrustedApplicationRef appRef;
        OSStatus returnStatus;
        returnStatus = SecTrustedApplicationCreateFromPath([(NSString*)obj cStringUsingEncoding:NSUTF8StringEncoding],
                                                           &appRef);
        
        if(returnStatus != errSecSuccess) {
            handle_sec_error(returnStatus, error);
            
            *stop = YES;
            failure = YES;
        } else {
            [trustedApplications addObject:(__bridge_transfer id)appRef];
        }
    }];
    
    if(failure) {
        return NO;
    }
    
    //Create an access object:
    err = SecAccessCreate((__bridge CFStringRef)accessLabel,
                          (__bridge CFArrayRef)trustedApplications, 
                          access);
    
    if(err != errSecSuccess) {
        return handle_sec_error(err, error);
    }
    
    return YES;
}

BOOL writeKey(const char * service, 
              const char * keyID, 
              const char * key, 
              NSArray *aclAppPaths,
              NSError * __autoreleasing *err)
{
	SecKeychainItemRef item = NULL;
    UInt32 passwordLength;
    void *passwordData;
    
	OSStatus returnStatus = SecKeychainFindGenericPassword(NULL, 
                                                           strlen(service),
                                                           service, 
                                                           strlen(keyID), 
                                                           keyID, 
                                                           &passwordLength, 
                                                           &passwordData, 
                                                           &item);
    
    if(returnStatus == errSecItemNotFound) { //Create a new key entry
        
        const char *description = [NSLocalizedString(@"Ovation Database Encryption Key", @"Ovation Database Encryption Key") cStringUsingEncoding:NSUTF8StringEncoding];
        
        //Set up the attribute vector (each attribute consists
        // of {tag, length, pointer}):
        SecKeychainAttribute attrs[] = {
            { kSecServiceItemAttr, strlen(service), (char*)service },
            { kSecAccountItemAttr, strlen(keyID), (char *)keyID },
            { kSecDescriptionItemAttr, strlen(description), (char*)description }, 
        };
        SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]),
            attrs };
        
        SecAccessRef access;
        if(!createAccess(@"Access label", 
                         aclAppPaths, 
                         &access, 
                         err)) {
            if(access != NULL) {
                CFRelease(access);
            }
            
            if(item != NULL) {
                CFRelease(item);
            }
            
            return NO;
        }
        
        returnStatus = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, 
                                         &attributes, 
                                         strlen(key), 
                                         key, 
                                         NULL, //default keychain
                                         access, 
                                         &item);
        
        
        if (returnStatus != errSecSuccess || !item) {
            if(item != NULL) {
                CFRelease(item);
            }
            
            return handle_sec_error(returnStatus, err);
        }
        
    } else { //Update password
        if(returnStatus == errSecSuccess) {
            SecKeychainItemFreeContent(NULL, passwordData);
        }
        
        returnStatus = SecKeychainItemModifyAttributesAndData (item,         // the item reference
                                                               NULL,            // no change to attributes
                                                               strlen(key),  // length of password
                                                               key         // pointer to password data
                                                               );
        
        if(returnStatus != errSecSuccess) {
            if(item != NULL) {
                CFRelease(item);
            }
            
            return handle_sec_error(returnStatus, err);
        }
        
    }
    
    if(item != NULL) {
        CFRelease(item);
    }
    
	return YES;
}