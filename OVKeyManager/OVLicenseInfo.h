//
//  OVLicenseInfo.h
//  OVKeyManager
//
//  Created by Barry Wark on 6/20/12.
//  Copyright (c) 2012 Physion Consulting LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OVLicenseInfo <NSObject>

@property (strong,nonatomic) NSString * institution;
@property (strong,nonatomic) NSString * group;
@property (strong,nonatomic) NSString * product;
@property (strong,nonatomic) NSString * licenseKey;

@property (nonatomic,readonly) NSString * keyID;

@end

@interface OVLicenseInfo : NSObject <OVLicenseInfo>

- (id)initWithInstitution:(NSString*)theInsititution
                    group:(NSString*)theGroup
                  product:(NSString*)theProduct
               licenseKey:(NSString*)theLicenseKey;

@property (strong,nonatomic) NSString * institution;
@property (strong,nonatomic) NSString * group;
@property (strong,nonatomic) NSString * product;
@property (strong,nonatomic) NSString * licenseKey;

@property (nonatomic,readonly) NSString * keyID;

@end