//
//  PHCAppDelegate.h
//  Ovation-Key-Manager
//
//  Created by Barry Wark on 6/19/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PHCSharedKeyRepository.h"

@interface PHCAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly,nonatomic,strong) NSString * updateActionTitle;
@property (readonly,nonatomic,strong) NSError * keyRepositoryError;

@property (nonatomic,strong) NSString * institution;
@property (nonatomic,strong) NSString * group;
@property (nonatomic,strong) NSString * sharedKey;
@property (nonatomic,strong) NSString * sharedKeyRepeat;
@property (nonatomic,strong) NSString * statusText;
@property (nonatomic,readonly) BOOL sharedKeyIsValid;

@property (nonatomic,strong) id<PHCSharedKeyRepository> systemKeyRepository;
@property (nonatomic,strong) id<PHCSharedKeyRepository> loginKeyRepository;

- (IBAction)addUpdateKey:(id)sender;

@end
