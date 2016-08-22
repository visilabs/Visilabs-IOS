//
//  BaseRequest.h
//  PigeoniOSSDK
//
//  Created by Ozan Uysal on 12/08/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EMJSONModel.h"

@interface EMBaseRequest : EMJSONModel

- (NSString *) getPath;
- (NSString *) getPort;
- (NSString *) getMethod;
- (NSString *) getSubdomain;

@end
