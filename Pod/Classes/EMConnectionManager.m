//
//  EMConnectionManager.m
//  EuroPush
//
//  Created by Ozan Uysal on 20/04/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "EMTools.h"
#import "EMConnectionManager.h"

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
#import "EMURLSessionDelegate.h"
#endif

#define TIMEOUT_INTERVAL 30

#define TEST_BASE_URL @"http://77.79.84.82"
#define PROD_BASE_URL @".euromsg.com"


@interface EMConnectionManager()

@property (nonatomic, strong) EMURLSessionDelegate *sessionDelegate;

+ (id) urlSession;

@end

@implementation EMConnectionManager

+ (EMConnectionManager *) sharedInstance {
    static EMConnectionManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        self.sessionDelegate = [EMURLSessionDelegate new];
    }
    return self;
}

+ (id) urlSession
{
    LogInfo(@"Using URL session");
    Class cls = NSClassFromString (@"NSURLSession");
    if (cls) {
        
        static NSURLSession *session = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            configuration.timeoutIntervalForRequest = 30;
            configuration.timeoutIntervalForResource = 60;
            configuration.HTTPMaximumConnectionsPerHost = 3;
            
            session = [NSURLSession sessionWithConfiguration:configuration];
            
        });
        return session;
        
    } else {
        return nil;
    }
}

/*
+ (id) urlBackgroundSession
{
    LogInfo(@"Using background session");
    Class cls = NSClassFromString (@"NSURLSession");
    if (cls) {
        
        static NSURLSession *session = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            NSURLSessionConfiguration *configuration;
            
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
                configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"mobi.appcent.EuroMessageMobileSDK"];
            } else {
                configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"mobi.appcent.EuroMessageMobileSDK"];
            }
            configuration.timeoutIntervalForRequest = 30;
            configuration.timeoutIntervalForResource = 60;
            configuration.HTTPMaximumConnectionsPerHost = 3;
            configuration.sessionSendsLaunchEvents = YES;
            configuration.allowsCellularAccess = YES;
            configuration.discretionary = YES;
            
            session = [NSURLSession sessionWithConfiguration:configuration delegate:[EMConnectionManager sharedInstance].sessionDelegate delegateQueue:[NSOperationQueue mainQueue]];
        });
        return session;
    } else {
        return nil;
    }
}
*/

- (void) setResponseBlock:(id) responseBlock {
    [self.sessionDelegate setResponseBlock:responseBlock];
}

- (void) request : (EMBaseRequest *) requestModel
          success:(void (^)(id response)) success
          failure:(void (^)(NSError *error)) failure {
    
    BOOL isProd = IS_PROD;
    if([EMTools retrieveUserDefaults:@"em_is_prod"]) {
        isProd = [[EMTools retrieveUserDefaults:@"em_is_prod"] intValue] == 1;
    }
    
    NSURL *url;
    if(isProd) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@/%@",requestModel.getSubdomain,PROD_BASE_URL,requestModel.getPath]];
    } else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:%@/%@",TEST_BASE_URL,requestModel.getPort,requestModel.getPath]];
        //url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",TEST_BASE_URL,requestModel.getPath]];
    }
    LogDebug(@"URL : %@",url);
    
    //UIApplicationState appState = [UIApplication sharedApplication].applicationState;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = requestModel.getMethod;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    [request setTimeoutInterval:TIMEOUT_INTERVAL];
    
    //[request setValue:[NSString stringWithFormat:@"Euro Mobil SDK iOS %@",[self getInfoString:@"CFBundleShortVersionString"]] forHTTPHeaderField:@"User-Agent"];
    //request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    if([requestModel.getMethod isEqualToString:@"POST"] || [requestModel.getMethod isEqualToString:@"PUT"]) {
        // pass parameters from request object
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:requestModel.toDictionary options:NSJSONWritingPrettyPrinted error:nil]];
    } else if([requestModel.getMethod isEqualToString:@"GET"]) {
        
    }
    
    if (request.HTTPBody) {
        LogDebug(@"Request to %@ with body %@",url,[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    }
    
    __weak __typeof__(self) weakSelf = self;
    id connectionHandler = ^(NSData *data,NSURLResponse *response,NSError *connectionError) {
        
        NSHTTPURLResponse *remoteResponse = (NSHTTPURLResponse *) response;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(connectionError == nil && (remoteResponse.statusCode == 200 || remoteResponse.statusCode == 201)) {
                
                if (weakSelf.debugMode) {
                    LogInfo(@"Server response code : %ld",(long)remoteResponse.statusCode);
                }
                __autoreleasing NSError *jsonError = nil;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                
                if (weakSelf.debugMode) {
                    LogInfo(@"Server response with success : %@",jsonObject);
                }
                
                if(jsonError == nil) {
                    success(jsonObject);
                } else {
                    success([NSDictionary new]);
                }
            } else {
                failure(connectionError);
                
                if (weakSelf.debugMode) {
                    LogInfo(@"Server response with failure : %@",remoteResponse);
                }
            }
        });
    };
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] <= 7.0)
    {
        if(self.debugMode) {
            LogInfo(@"Running on IOS 6");
        }
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            NSHTTPURLResponse *remoteResponse = (NSHTTPURLResponse *) response;
            
            if(connectionError == nil && (remoteResponse.statusCode == 200 || remoteResponse.statusCode == 201)) {
                
                if(weakSelf.debugMode) {
                    LogInfo(@"Server response code : %ld",(long)remoteResponse.statusCode);
                }
                __autoreleasing NSError *jsonError = nil;
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                
                if (weakSelf.debugMode) {
                    LogInfo(@"Server response with success : %@",jsonObject);
                }
                
                if(jsonError == nil) {
                    success(jsonObject);
                } else {
                    success([NSDictionary new]);
                }
            } else {
                failure(connectionError);
                
                if (weakSelf.debugMode) {
                    LogInfo(@"Server response with failure : %@",remoteResponse);
                }
            }
        }];
    } else {
        /*if (appState != UIApplicationStateActive) {
            [request setNetworkServiceType:NSURLNetworkServiceTypeBackground];
            NSURLSessionDownloadTask *downloadTask = [[[self class] urlBackgroundSession] downloadTaskWithRequest:request];
            [downloadTask resume];
        } else {*/
            NSURLSessionDataTask *dataTask = [[[self class] urlSession] dataTaskWithRequest:request completionHandler:connectionHandler];
            [dataTask resume];
        //}
    }
}

- (void) request : (NSString *) url {
    NSURL *requestUrl = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestUrl];
    LogInfo(@"Request to : %@",url);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        LogInfo(@"Server responded. Error  : %@",connectionError);
    }];
}

@end
