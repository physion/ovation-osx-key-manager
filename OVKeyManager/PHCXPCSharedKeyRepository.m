//
//  PHCXPCSharedKeyRepository.m
//  Ovation-Key-Manager
//
//  Created by Barry Wark on 6/19/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

#import "PHCXPCSharedKeyRepository.h"
#import "PHCAppDelegate.h"
#import "PHCErrors.h"
#import "OVKeyManagerHelperAPI.h"


@interface PHCXPCSharedKeyRepository ()
- (BOOL)blessHelperWithLabel:(NSString *)label
                       error:(NSError **)error;
- (BOOL)connectXPC:(NSString*)bundleID error:(repository_error_callback)err;

@property (unsafe_unretained, nonatomic) xpc_connection_t connection;
@property (strong,nonatomic) NSString * label;

@end

const char * SERVICE_NAME = "com.physionconsulting.OVKeyManagerHelper";

@implementation PHCXPCSharedKeyRepository 

@synthesize connection;
@synthesize label;


- (id)initWithLabel:(NSString*)helperLabel connectionErrorCallback:(repository_error_callback)err {
 
    if((self = [super init])) {
        self.label = helperLabel;
    }
    
    return self;
}

- (void)dealloc {
    if(self.connection != NULL) {
        xpc_release(self.connection);
        self.connection = NULL;
    }
}

- (BOOL)connectXPC:(NSString*)bundleID error:(repository_error_callback)errCallback {
    
    if(self.connection != NULL) {
        return YES;
    }
    
    NSError *err;
    
    if (![self blessHelperWithLabel:bundleID error:&err]) {
        dispatch_async(dispatch_get_main_queue(), ^() { errCallback(err); });
        return NO;
    }
    
    self.connection = xpc_connection_create_mach_service(SERVICE_NAME, 
                                                         NULL, 
                                                         XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
    
    if (!self.connection) {
                dispatch_async(dispatch_get_main_queue(), ^() { 
                    errCallback([NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN 
                                code:CONNECTION_ERROR
                            userInfo:[NSDictionary dictionaryWithObject:@"Failed to create XPC connection"
                                                                 forKey:NSLocalizedDescriptionKey]]);
                });
        
        return NO;
    }
    
    xpc_connection_set_event_handler(self.connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
        
        if (type == XPC_TYPE_ERROR) {
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithCString:xpc_dictionary_get_string(event, _xpc_error_key_description)
                                                                                               encoding:NSUTF8StringEncoding],
                                  NSLocalizedDescriptionKey,
                                  nil];
            
            if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                
                        dispatch_async(dispatch_get_main_queue(), ^() { errCallback([NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN
                                                code:CONNECTION_INTERRUPTED
                                            userInfo:info]);
                        });
                
            } else if (event == XPC_ERROR_CONNECTION_INVALID) {
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithCString:xpc_dictionary_get_string(event, _xpc_error_key_description)
                                                                                                   encoding:NSUTF8StringEncoding],
                                      NSLocalizedDescriptionKey,
                                      nil];
                dispatch_async(dispatch_get_main_queue(), ^() { errCallback([NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN
                                                                                                code:INVALID_CONNECTION_ERROR
                                                                                            userInfo:info]);
                });
                xpc_release(self.connection);
                self.connection = NULL;
                
            } else {
                dispatch_async(dispatch_get_main_queue(), ^() { errCallback([NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN
                                                                                                code:CONNECTION_ERROR
                                                                                            userInfo:info]);
                });
                xpc_release(self.connection);
                self.connection = NULL;
            }
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^() { errCallback([NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN
                                                                                            code:UNKNOWN_XPC_ERROR
                                                                                        userInfo:[NSDictionary dictionaryWithObject:@"Unknown XPC Event"
                                                                                                                             forKey:NSLocalizedDescriptionKey]]);
            });
            xpc_release(self.connection);
            self.connection = NULL;
        }
    });
    
    xpc_connection_resume(self.connection);
    
    return YES;
}

- (void)addKey:(NSString*)key forLicense:(id<OVLicenseInfo>)licenseInfo 
       success:(void (^)(void))successBlock
         error:(repository_error_callback)err
{
    NSParameterAssert(licenseInfo != nil);

    if(self.connection == NULL) {
        if(![self connectXPC:self.label error:err]) {
            return;
        }
    }
    
    NSAssert(self.connection != NULL, @"No XPC connection");
    
    xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(message, COMMAND_KEY, ADD_KEY_COMMAND);
    xpc_dictionary_set_string(message, KEY_ID_KEY, [[licenseInfo keyID] cStringUsingEncoding:NSUTF8StringEncoding]);
    xpc_dictionary_set_string(message, SHARED_ENCRYPTION_KEY_KEY, [key cStringUsingEncoding:NSUTF8StringEncoding]);
    
    xpc_connection_send_message_with_reply(self.connection, message, dispatch_get_main_queue(), ^(xpc_object_t event) {
        
        BOOL success = xpc_dictionary_get_bool(event, RESULT_STATUS_KEY);
        if(!success) {
            
            const char * errMsgCString = xpc_dictionary_get_string(event, RESULT_ERR_MSG_KEY);
            
            
            NSString * errMsg = errMsgCString != NULL ? [NSString stringWithCString:errMsgCString
                                                                           encoding:NSUTF8StringEncoding] : NSLocalizedString(@"Unknown error", @"Unknown error");
            
            NSError *error = [NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN 
                                                 code:KEYCHAIN_ERROR
                                             userInfo:[NSDictionary dictionaryWithObject:errMsg
                                                                                  forKey:NSLocalizedDescriptionKey]];
            dispatch_async(dispatch_get_main_queue(), ^() { err(error); });
        } else {
            dispatch_async(dispatch_get_main_queue(), successBlock);
        }
    });
}

- (void)updateKey:(NSString*)key forLicense:(id<OVLicenseInfo>)licenseInfo 
          success:(void (^)(void))success
            error:(repository_error_callback)err {
    
}

- (NSSet*)keys:(repository_error_callback)error {
    return [NSSet set];
}

- (BOOL)blessHelperWithLabel:(NSString *)helperLabel
                       error:(NSError **)error {
    
	BOOL result = NO;
    
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags		=	(kAuthorizationFlagDefaults | 
                                         kAuthorizationFlagInteractionAllowed | 
                                         kAuthorizationFlagPreAuthorize | 
                                         kAuthorizationFlagExtendRights);
    
	AuthorizationRef authRef = NULL;
	
	/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
	OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authRef);
	if (status != errAuthorizationSuccess) {
        if(error != NULL) {
            *error = [NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN
                                         code:JOB_BLESS_ERROR
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Authorization failed (code %d)", @"Authorization failed"), status]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
	} else {
        
        OSStatus status = AuthorizationCopyRights(authRef, &authRights, kAuthorizationEmptyEnvironment, flags, NULL);
        if(status != errAuthorizationSuccess) {
            if(error != NULL) {
                *error = [NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN
                                             code:JOB_BLESS_ERROR
                                         userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Authorization failed (code %d)", @"Authorization failed"), status]
                                                                              forKey:NSLocalizedDescriptionKey]];
            }
        } else {
            
            /* This does all the work of verifying the helper tool against the application
             * and vice-versa. Once verification has passed, the embedded launchd.plist
             * is extracted and placed in /Library/LaunchDaemons and then loaded. The
             * executable is placed in /Library/PrivilegedHelperTools.
             */
            CFErrorRef err;
            result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)helperLabel, authRef, &err);
            if(!result && error != NULL) {
                *error = (__bridge NSError*)err;
            }
        }
	}
	
	return result;
}
@end
