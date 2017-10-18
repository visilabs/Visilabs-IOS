//
//  VisilabsHttpClient.m
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "Visilabs.h"
#import "VisilabsDefines.h"
#import "VisilabsHttpClient.h"
#import "VisilabsJSON.h"

@interface VisilabsHttpClient ()
@property (nonatomic, copy) void (^successHandler)(VisilabsResponse *resp);
@property (nonatomic, copy) void (^failureHandler)(VisilabsResponse *resp);
@property (nonatomic, copy) NSURLSession* session;
@end

@implementation VisilabsHttpClient

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}


- (NSMutableURLRequest*)request:(VisilabsAction*)visilabsAction withUrl:(NSURL*)url {
    NSMutableURLRequest* request;
    if (visilabsAction.cacheTimeout > 0) {
        request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:visilabsAction.cacheTimeout];
    } else { // use default cache timeout (ie: set by server)
        request = [[NSMutableURLRequest alloc] initWithURL: url];
    }
    request.HTTPMethod = visilabsAction.requestMethod;
    
    if([[Visilabs callAPI] userAgent]){
        [request setValue:[[Visilabs callAPI] userAgent] forHTTPHeaderField:@"User-Agent"];
    }
    
    return request;
}

- (void)sendRequest:(VisilabsAction *)visilabsAction
         AndSuccess:(void (^)(VisilabsResponse *success))sucornil
         AndFailure:(void (^)(VisilabsResponse *failed))failornil {
    
    self.successHandler = sucornil;
    self.failureHandler = failornil;
    
    NSURL *apicall = visilabsAction.buildURL;
    
    if (! [[Visilabs callAPI] isOnline]) {
        VisilabsResponse *res = [[VisilabsResponse alloc] init];
        if(apicall){
            res.targetURL = [apicall absoluteString];
        }
        [res setError:[NSError errorWithDomain:@"VisilabsHttpClient"
                                          code:VisilabsSDKNetworkOfflineErrorType
                                      userInfo:@{
                                                 @"error" : @"offline"
                                                 }]];
        [self failWithResponse:res AndAction:visilabsAction];
        return;
    }
    
    
    
    //DLog(@"Request URL is : %@", [apicall absoluteString]);
    
    NSMutableURLRequest* brequest = [self request:visilabsAction withUrl:apicall];
    //NSURLRequest* request = [brequest copy];
    [brequest copy];
    
    brequest.timeoutInterval = visilabsAction.requestTimeout;
    
    NSURLSessionDataTask * task = [_session dataTaskWithRequest:brequest completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        NSString *encodingName = [response textEncodingName];
        NSStringEncoding encodingType = NSUTF8StringEncoding;
        if (encodingName != nil) {
            encodingType = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName));
        }
        NSString* reponseAsRawString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:encodingType];
        int statusCode = (int)((NSHTTPURLResponse*)response).statusCode;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                //DLog(@"Error %@", error.description);
                VisilabsResponse *visilabsResponse = [[VisilabsResponse alloc] init];
                if(apicall){
                    visilabsResponse.targetURL = [apicall absoluteString];
                }
                visilabsResponse.rawResponseAsString = reponseAsRawString;
                visilabsResponse.rawResponse = data;
                visilabsResponse.error = error;
                [self failWithResponse:visilabsResponse AndAction:visilabsAction];
                return;
            }
            
            //DLog(@"reused cache %lu", (unsigned long)request.cachePolicy);
            //DLog(@"Response status : %d", statusCode);
            //DLog(@"Response data : %@", ((NSHTTPURLResponse*)response).description);
            
            // parse, build response, delegate
            VisilabsResponse *visilabsResponse = [[VisilabsResponse alloc] init];
            visilabsResponse.responseStatusCode = (int)((NSHTTPURLResponse*)response).statusCode;
            visilabsResponse.rawResponseAsString = reponseAsRawString;
            visilabsResponse.rawResponse = data;
            if(apicall){
                visilabsResponse.targetURL = [apicall absoluteString];
            }
            [visilabsResponse parseResponseData:data];
            
            
            @try{
                if (statusCode == 200) {
                    [self successWithResponse:visilabsResponse AndAction:visilabsAction];
                    return;
            }
            }@catch(NSException *ex){
                return;
            }
            
            NSString *msg = [visilabsResponse.parsedResponse valueForKey:@"msg"];
            if (nil == msg) {
                msg = [visilabsResponse.parsedResponse valueForKey:@"message"];
                if (nil == msg) {
                    msg = reponseAsRawString;
                }
            }
            NSError *err = [NSError errorWithDomain:@"VisilabsHTTPRequestErrorDomain"
                                               code:statusCode
                                           userInfo:@{NSLocalizedDescriptionKey : msg}];
            visilabsResponse.error = err;
            [self failWithResponse:visilabsResponse AndAction:visilabsAction];
        });
    }];
    
    [task resume];
    
}

- (void)successWithResponse:(VisilabsResponse *)visilabsRes AndAction:(VisilabsAction *)action {
    // if user has defined their own call back pass control to them
    if (self.successHandler) {
        return self.successHandler(visilabsRes);
    }
    
    SEL sucSel = @selector(requestDidSucceedWithResponse:);
    if (action.delegate && [action.delegate respondsToSelector:sucSel]) {
        [(VisilabsAction *)action.delegate performSelectorOnMainThread:sucSel
                                                   withObject:visilabsRes
                                                waitUntilDone:YES];
    }
}

- (void)failWithResponse:(VisilabsResponse *)visilabsRes AndAction:(VisilabsAction *)action {
    if (self.failureHandler) {
        return self.failureHandler(visilabsRes);
    }
    
    SEL delFailSel = @selector(requestDidFailWithResponse:);
    if (action.delegate && [action.delegate respondsToSelector:delFailSel]) {
        [(VisilabsAction *)action.delegate performSelectorOnMainThread:delFailSel
                                                   withObject:visilabsRes
                                                waitUntilDone:YES];
    }
}

@end
