//
//  BaseRequest.h
//  PigeoniOSSDK
//
//  Created by Ozan Uysal on 12/08/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EMBaseRequest.h"


@interface EMRegisterRequest : EMBaseRequest


@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSString *os;
@property (nonatomic, strong) NSString *osVersion;
@property (nonatomic, strong) NSString *deviceType;
@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic, strong) NSString *carrier;
@property (nonatomic, strong) NSString *local;
@property (nonatomic, strong) NSString *appVersion;
@property (nonatomic, strong) NSString *sdkVersion;
@property (nonatomic, strong) NSNumber *firstTime;
@property (nonatomic, strong) NSString *identifierForVendor;
@property (nonatomic, strong) NSString *advertisingIdentifier;

@property (nonatomic, strong) NSMutableDictionary *extra;

@end
