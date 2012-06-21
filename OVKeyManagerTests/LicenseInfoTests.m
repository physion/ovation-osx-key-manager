//
//  LicenseInfoTests.m
//  OVKeyManager
//
//  Created by Barry Wark on 6/20/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#import "LicenseInfoTests.h"
#import "OVLicenseInfo.h"

@implementation LicenseInfoTests

- (void)testShouldBuildKeyID {
    NSString *inst = @"My Institution";
    NSString *grp = @"My Group";
    NSString *product = @"My product";
    NSString *key = @"LICENSE_KEY";
    
    id<OVLicenseInfo> l = [[OVLicenseInfo alloc] initWithInstitution:inst group:grp product:product licenseKey:key];
    
    NSString *expected = [NSString stringWithFormat:@"%@::%@::%@", inst, grp, product];
    STAssertEqualObjects(expected, l.keyID, nil);
}
@end
