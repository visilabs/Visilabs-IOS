//
//  VisilabsResponse.h
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VisilabsResponse : NSObject


/** Get the generated target URL as NSString */
@property (nonatomic, strong) NSString *targetURL;

/** Get the response as NSArray */ /*egemen*/
@property (nonatomic, strong) NSArray *responseArray;

/** Get the raw response data */
@property (nonatomic, strong) NSData *rawResponse;

/** Get the raw response data as NSString */
@property (nonatomic, strong) NSString *rawResponseAsString;

/** Get the response data as NSDictionary */
@property (nonatomic, strong) NSDictionary *parsedResponse;

/** Get the response's status code */
@property (nonatomic, assign) int responseStatusCode;

/** Get the error of the response */
@property (nonatomic, strong) NSError *error;

/** Parse the response string (JSON format)
 
 @param res The response string
 */
- (void)parseResponseString:(NSString *)res;

/** Parse the response data (JSON format)
 
 @param dat The response data
 */
- (void)parseResponseData:(NSData *)dat;

@end

