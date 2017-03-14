//
//  BaseRequest.m
//  PigeoniOSSDK
//
//  Created by Ozan Uysal on 12/08/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import "EMSettingsRequest.h"

@implementation EMSettingsRequest

- (NSString *) getPath {
    return @"settings";
}

- (NSString *) getMethod {
    return @"GET";
}

- (NSString *) getPort {
    return @"4243";
}

@end
