//
//  PHCLoginSharedKeyRepository.m
//  OVKeyManager
//
//  Created by Barry Wark on 6/20/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#import "PHCLoginSharedKeyRepository.h"
#import "OVKeyManagerHelperAPI.h"

@implementation PHCLoginSharedKeyRepository

- (NSSet*)keys:(repository_error_callback)error {
    return nil;
}

- (void)addKey:(NSString*)key forLicense:(id<OVLicenseInfo>)licenseInfo 
       success:(void (^)())success
         error:(repository_error_callback)err {
    
    NSError *error;
    if(writeKey("com.physionconsulting.ovation", 
                [licenseInfo.keyID cStringUsingEncoding:NSUTF8StringEncoding], 
                [key cStringUsingEncoding:NSUTF8StringEncoding],
                [NSArray arrayWithObject:@"/opt/object/mac86_64/bin/ooqs"],
                &error)) {
        dispatch_async(dispatch_get_main_queue(), success);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^() { err(error); });
    }
}

- (void)updateKey:(NSString*)key forLicense:(id<OVLicenseInfo>)licenseInfo 
          success:(void (^)())success
            error:(repository_error_callback)err {

    
}

@end
