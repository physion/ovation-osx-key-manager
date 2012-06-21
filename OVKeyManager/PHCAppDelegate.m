//
//  PHCAppDelegate.m
//  Ovation-Key-Manager
//
//  Created by Barry Wark on 6/19/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#import "PHCAppDelegate.h"
#import "PHCErrors.h"
#import "PHCXPCSharedKeyRepository.h"
#import "PHCLoginSharedKeyRepository.h"

@interface PHCAppDelegate ()

@property (readwrite,nonatomic,strong) NSError * keyRepositoryError;

@end

@implementation PHCAppDelegate

@synthesize window;
@synthesize keyRepositoryError;
@synthesize updateActionTitle;
@synthesize systemKeyRepository;
@synthesize institution;
@synthesize group;
@synthesize sharedKey;
@synthesize statusText;
@synthesize loginKeyRepository;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{   
    self.systemKeyRepository = [[PHCXPCSharedKeyRepository alloc] initWithLabel:@"com.physionconsulting.OVKeyManagerHelper" 
                                                   connectionErrorCallback:^(NSError *err) {
                                                       self.keyRepositoryError = err;
                                                   }];
    self.loginKeyRepository = [[PHCLoginSharedKeyRepository alloc] init];
}

- (NSString*)updateActionTitle {
    return NSLocalizedString(@"Update", @"Update key");
}

- (IBAction)addUpdateKey:(id)sender {
    
    id<OVLicenseInfo> licenseInfo = [[OVLicenseInfo alloc] initWithInstitution:self.institution
                                                                         group:self.group 
                                                                       product:@"Ovation"
                                                                    licenseKey:nil];
    
    self.statusText = nil;
    self.keyRepositoryError = nil;
    
    //Add the key to the login, then the system keychain
    [self.loginKeyRepository addKey:self.sharedKey 
                         forLicense:licenseInfo
                            success:^() {
                                self.statusText = NSLocalizedString(@"User key updated succesfully", @"Shared encryption key added/updated in login keychain.");
                                
                                [self.systemKeyRepository addKey:self.sharedKey
                                                      forLicense:licenseInfo
                                                         success:^() {
                                                             self.statusText = NSLocalizedString(@"Key updated succesfully", @"Shared encryption key Added/Updated Succesfully");
                                                         }
                                                           error:^(NSError *err) {
                                                               self.keyRepositoryError = err; 
                                                           }];
                            }
                              error:^(NSError *err) {
                                  self.keyRepositoryError = err;
                              }];
}

@end