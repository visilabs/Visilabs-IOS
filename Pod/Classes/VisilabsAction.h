//
//  VisilabsAction.h
//  Visilabs-IOS
//
//  Created by Visilabs on 7.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsResponseDelegate.h"

@class VisilabsHttpClient;

/**
 Base class for all API request classes
 */
@interface VisilabsAction : NSObject{
    @protected
    NSMutableDictionary *_args;
    NSMutableDictionary *_headers;
    BOOL _async;
    VisilabsHttpClient *_httpClient;
}

    
/** The type of the request */
@property (nonatomic, strong) NSString *method;

/** The HTTP request method */
@property (nonatomic, strong) NSString *requestMethod;

/** The timeout value of the request  Default to 30 seconds */
@property (nonatomic, assign) NSTimeInterval requestTimeout;

/** The response delegate for this request.
 
 @see VisilabsResponseDelegate
 */
@property (nonatomic, weak) id<VisilabsResponseDelegate> delegate;

/** The HTTP headers of the request */
@property (nonatomic, strong) NSDictionary *headers;

/** How long the response should be cached for. The response won't be cached if it's not set.
 */
@property (nonatomic, assign) NSUInteger cacheTimeout;

/** Set/Get the parameters for the API request.
 
 @return Returns the parameters.
 */
@property (nonatomic, strong) NSDictionary *args;

/** Get the parameters for the API request as NSString.
 
 @return Returns the parameters as string.
 */
- (NSString *)argsAsString;

/** Get the URL of the API request
 
 @return Returns the URL
 */
@property (nonatomic, strong, readonly) NSURL *buildURL;

/** The relative path of the API request
 
 @return The API request's relative path
 */
@property (nonatomic, strong) NSString *path;

/** Excute the API request synchronously with the given success and failure
 blocks.
 
 @warning This will block the application's main UI thread
 @param sucornil The block to be executed if the request is successful. If it's
 nil, the delegate's [VisilabsResponseDelegate requestDidSucceedWithResponse:] will be
 exectued.
 @param failornil The block to be executed if the request is failed. If it's nil,
 the delegate's [VisilabsResponseDelegate requestDidFailWithResponse:] will be
 exectued.
 
 @see VisilabsResponseDelegate
 */
- (void)execWithSuccess:(void (^)(VisilabsResponse *success))sucornil AndFailure:(void (^)(VisilabsResponse *failed))failornil;

/** Excute the API request asynchronously with the given success and failure
 blocks.
 
 This is the recommended way to execute the request.
 
 @param sucornil The block to be executed if the request is successful. If it's
 nil, the delegate's [VisilabsResponseDelegate requestDidSucceedWithResponse:] will be
 exectued.
 @param failornil The block to be executed if the request is failed. If it's nil,
 the delegate's [VisilabsResponseDelegate requestDidFailWithResponse:] will be
 exectued.
 @see VisilabsResponseDelegate
 */
- (void)execAsyncWithSuccess:(void (^)(VisilabsResponse *success))sucornil
                  AndFailure:(void (^)(VisilabsResponse *failed))failornil;

@end
