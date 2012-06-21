//
//  OVKeyManagerTestBase.m
//  OVKeyManagerTestBase
//
//  Created by Barry Wark on 6/20/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#import "OVKeyManagerTestBase.h"

@implementation OVKeyManagerTestBase

- (NSSet*)keys:(repository_error_callback)error { return  nil; }
- (void)addKey:(NSString*)key forLicense:(id<OVLicenseInfo>)licenseInfo 
       success:(void (^)())success
         error:(repository_error_callback)err {}
- (void)updateKey:(NSString*)key forLicense:(id<OVLicenseInfo>)licenseInfo 
          success:(void (^)())success
            error:(repository_error_callback)err {}

@end

