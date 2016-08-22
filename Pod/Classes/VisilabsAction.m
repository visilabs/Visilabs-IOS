//
//  VisilabsAction.m
//  Visilabs-IOS
//
//  Created by Visilabs on 7.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "Visilabs.h"

#import "VisilabsHttpClient.h"
#import "VisilabsDefines.h"

@implementation VisilabsAction

- (instancetype)init {
    self = [super init];
    if (self) {
        _args = [NSMutableDictionary dictionary];
        _httpClient = [[VisilabsHttpClient alloc] init];
        _headers = [NSMutableDictionary dictionary];
        self.requestMethod = @"GET";
        self.requestTimeout = 30;
    }
    return self;
}

- (void)setArgs:(NSDictionary *)arguments {
    _args = [NSMutableDictionary dictionaryWithDictionary:arguments];
    //DLog(@"args set to  %@", _args);
}

- (NSString *)argsAsString {
    return [_args JSONString];
}

- (NSURL *)buildURL {
    NSString *url =  [[Visilabs callAPI] targetURL];
    NSURL *uri = [[NSURL alloc] initWithString:url];
    return uri;
}


- (void)execWithSuccess:(void (^)(VisilabsResponse *success))sucornil AndFailure:(void (^)(VisilabsResponse *failed))failornil {
    [self exec:FALSE WithSuccess:sucornil AndFailure:failornil];
}

- (void)execAsyncWithSuccess:(void (^)(VisilabsResponse *success))sucornil
                  AndFailure:(void (^)(VisilabsResponse *failed))failornil {
    [self exec:TRUE WithSuccess:sucornil AndFailure:failornil];
}

- (void)exec:(BOOL)pAsync
 WithSuccess:(void (^)(VisilabsResponse *success))sucornil
  AndFailure:(void (^)(VisilabsResponse *failed))failornil {
    _async = pAsync;
    [_httpClient sendRequest:self AndSuccess:sucornil AndFailure:failornil];
}

@end
