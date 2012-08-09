//
//  UpdateEnableTest.m
//  OVKeyManager
//
//  Created by Barry Wark on 8/9/12.
//
//

#import "UpdateEnableTest.h"
#import "PHCAppDelegate.h"

@implementation UpdateEnableTest

- (void)testShouldValidateMatchingKeys {
    PHCAppDelegate *appDelegate = [[PHCAppDelegate alloc] init];
    
    appDelegate.institution = @"institution";
    appDelegate.group = @"group";
    appDelegate.sharedKey = @"sharedKey";
    appDelegate.sharedKeyRepeat = appDelegate.sharedKey;
    
    STAssertTrue(appDelegate.sharedKeyIsValid, nil);
}

- (void)testShouldNotValidateDifferentKeys {
    PHCAppDelegate *appDelegate = [[PHCAppDelegate alloc] init];
    
    appDelegate.institution = @"institution";
    appDelegate.group = @"group";
    appDelegate.sharedKey = @"sharedKey";
    appDelegate.sharedKeyRepeat = @"not matching";
    
    STAssertFalse(appDelegate.sharedKeyIsValid, nil);
}

- (void)testShouldNotValidateEmptySharedKey {
    PHCAppDelegate *appDelegate = [[PHCAppDelegate alloc] init];
    
    appDelegate.institution = @"institution";
    appDelegate.group = @"group";
    appDelegate.sharedKey = @"";
    appDelegate.sharedKeyRepeat = appDelegate.sharedKey;
    
    STAssertFalse(appDelegate.sharedKeyIsValid, nil);
}

- (void)testShouldNotValidateEmptySharedKeyAndNilRepeat {
    PHCAppDelegate *appDelegate = [[PHCAppDelegate alloc] init];
    
    appDelegate.institution = @"institution";
    appDelegate.group = @"group";
    appDelegate.sharedKey = @"";
    appDelegate.sharedKeyRepeat = nil;
    
    STAssertFalse(appDelegate.sharedKeyIsValid, nil);
}

- (void)testShouldNotValidateNilSharedKey {
    PHCAppDelegate *appDelegate = [[PHCAppDelegate alloc] init];
    
    appDelegate.institution = @"institution";
    appDelegate.group = @"group";
    appDelegate.sharedKeyRepeat = @"not matching";
    appDelegate.sharedKey = nil;
    
    STAssertFalse(appDelegate.sharedKeyIsValid, nil);
}

- (void)testShouldNotValidateNilSharedKeyRepeat {
    PHCAppDelegate *appDelegate = [[PHCAppDelegate alloc] init];
    
    appDelegate.institution = @"institution";
    appDelegate.group = @"group";
    appDelegate.sharedKeyRepeat = nil;
    appDelegate.sharedKey = @"shared key";
    
    STAssertFalse(appDelegate.sharedKeyIsValid, nil);
}

@end
