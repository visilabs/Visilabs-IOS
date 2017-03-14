//
//  EMConnectionManager.h
//  EuroPush
//
//  Created by Ozan Uysal on 20/04/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EMLogging.h"

#import "EMBaseRequest.h"

#define IS_PROD YES

@interface EMConnectionManager : NSObject

- (void) setResponseBlock:(id) responseBlock;

+ (EMConnectionManager *) sharedInstance;

- (void) request : (EMBaseRequest *) request
          success:(void (^)(id response)) success
          failure:(void (^)(NSError *error)) failure;

- (void) request : (NSString *) url;

@property (nonatomic, assign) BOOL debugMode;

@end
