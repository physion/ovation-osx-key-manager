//
//  AddKeyTest.m
//  OVKeyManager
//
//  Created by Barry Wark on 6/20/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#import "AddKeyTest.h"
#import "PHCAppDelegate.h"
#import "PHCErrors.h"

@interface PHCAppDelegate (TestingMethods)

- (void)_testSetKeyManagerError:(NSError*)err;

@end

@implementation AddKeyTest
@synthesize addCalled;

- (void)addKey:(NSString *)key forLicense:(id<OVLicenseInfo>)licenseInfo success:(void (^)())success error:(repository_error_callback)err {
    self.addCalled = YES;
}
- (void)testShouldAddKey {
    PHCAppDelegate *appDelegate = [[PHCAppDelegate alloc] init];
    
    appDelegate.institution = @"institution";
    appDelegate.group = @"group";
    appDelegate.sharedKey = @"sharedKey";
    
    appDelegate.systemKeyRepository = self;
    
    [appDelegate addUpdateKey:self]; 
    
    STAssertTrue(self.addCalled, nil);
}

- (void)testShouldClearStatusOnAddUpdate {
    PHCAppDelegate *appDelegate = [[PHCAppDelegate alloc] init];
    
    appDelegate.statusText = @"SOME TEXT";
    
    appDelegate.institution = @"institution";
    appDelegate.group = @"group";
    appDelegate.sharedKey = @"sharedKey";
    
    appDelegate.systemKeyRepository = self;
    
    [appDelegate addUpdateKey:self]; 
    
    STAssertNil(appDelegate.statusText, nil);
}

- (void)testShouldClearErrorOnAddUpdate {
    PHCAppDelegate *appDelegate = [[PHCAppDelegate alloc] init];
    
    [appDelegate _testSetKeyManagerError:[NSError errorWithDomain:OVATION_KEY_MANAGER_ERROR_DOMAIN code:0 userInfo:[NSDictionary dictionary]]];
    
    appDelegate.institution = @"institution";
    appDelegate.group = @"group";
    appDelegate.sharedKey = @"sharedKey";
    
    appDelegate.systemKeyRepository = self;
    
    [appDelegate addUpdateKey:self]; 
    
    STAssertNil(appDelegate.keyRepositoryError, nil);
}

@end



@implementation PHCAppDelegate (TestingMethods)

- (void)_testSetKeyManagerError:(NSError*)err {
    [self setValue:err forKey:@"keyRepositoryError"];
}

@end
