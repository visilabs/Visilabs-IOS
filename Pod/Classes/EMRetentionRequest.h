//
//  BaseRequest.h
//  PigeoniOSSDK
//
//  Created by Ozan Uysal on 12/08/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EMBaseRequest.h"


@interface EMRetentionRequest : EMBaseRequest

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *choiceId;
@property (nonatomic, strong) NSString *pushId;

@end
