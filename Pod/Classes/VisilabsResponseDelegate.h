//
//  VisilabsResponseDelegate.h
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VisilabsResponse;
@class VisilabsAction;

/**
 The delegate class to process the response data. If callback blocks are not
 used in the API requests, this protocol should be implemented and assigned to
 an instance of VisilabsAction
 */

@protocol VisilabsResponseDelegate <NSObject>

@required

/** Executed if the request is successful
 
 @param res The response object
 */
- (void)requestDidSucceedWithResponse:(VisilabsResponse *)res;

/** Executed if the request is failed
 
 @param res The response object
 */
- (void)requestDidFailWithResponse:(VisilabsResponse *)res;

@end
