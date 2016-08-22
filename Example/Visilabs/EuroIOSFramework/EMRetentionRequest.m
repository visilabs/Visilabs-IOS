//
//  BaseRequest.m
//  PigeoniOSSDK
//
//  Created by Ozan Uysal on 12/08/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import "EMRetentionRequest.h"

@implementation EMRetentionRequest


- (NSString *) getPath {
    return @"retention";
}

- (NSString *) getMethod {
    return @"POST";
}

- (NSString *) getPort {
    return @"4242";
}

- (NSString *) getSubdomain {
    return @"pushr";
}

@end
