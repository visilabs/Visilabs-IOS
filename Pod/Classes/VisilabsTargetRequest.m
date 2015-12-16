//
//  VisilabsTargetRequest.m
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsTargetRequest.h"
#import "Visilabs.h"
#import "VisilabsDefines.h"
#import "VisilabsPersistentTargetManager.h"

@implementation VisilabsTargetRequest

- (NSURL *)buildURL {
    @synchronized(self)
    {
        NSMutableString *targetURL = [[[Visilabs callAPI] targetURL] mutableCopy];
        NSString *queryParameters =[self getParametersAsQueryString];
        targetURL = [[targetURL stringByAppendingString:queryParameters] mutableCopy];
        DLog(@"Request url is %@", targetURL);
        NSURL *uri = [[NSURL alloc] initWithString:targetURL];
        return uri;
    }
}


- (NSString *)getParametersAsQueryString {
    
    if(![[Visilabs callAPI] organizationID] || [[[Visilabs callAPI] organizationID] length] == 0
       || ![[Visilabs callAPI] siteID] || [[[Visilabs callAPI] siteID] length] == 0)
    {
        return nil;
    }
    
    
    NSMutableString *queryParameters = [NSMutableString stringWithFormat:@"?%@=%@&%@=%@", [VisilabsConfig ORGANIZATIONID_KEY], [[Visilabs callAPI] organizationID], [VisilabsConfig SITEID_KEY], [[Visilabs callAPI] siteID]];
    
    if([[Visilabs callAPI] cookieID] && [[[Visilabs callAPI] cookieID] length] > 0)
    {
        NSString* encodedCookieIDValue = [[Visilabs callAPI] urlEncode:[[Visilabs callAPI] cookieID]];
        NSString *cookieParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig COOKIEID_KEY], encodedCookieIDValue];
        queryParameters = [[queryParameters stringByAppendingString:cookieParameter] mutableCopy];
    }
    
    if([[Visilabs callAPI] exVisitorID] && [[[Visilabs callAPI] exVisitorID] length] > 0)
    {
        NSString* encodedExVisitorIDValue = [[Visilabs callAPI] urlEncode:[[Visilabs callAPI] exVisitorID]];
        NSString *exVisitorIDParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig EXVISITORID_KEY], encodedExVisitorIDValue];
        queryParameters = [[queryParameters stringByAppendingString:exVisitorIDParameter] mutableCopy];
    }
    
    if([self zoneID] && [[self zoneID] length] > 0)
    {
        NSString* encodedZoneIDValue = [[Visilabs callAPI] urlEncode:[self zoneID]];
        NSString *zoneIDParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig ZONE_ID_KEY], encodedZoneIDValue];
        queryParameters = [[queryParameters stringByAppendingString:zoneIDParameter] mutableCopy];
    }
    
    if([self productCode] && [[self productCode] length] > 0)
    {
        NSString* encodedProductCodeValue = [[Visilabs callAPI] urlEncode:[self productCode]];
        NSString *productCodeParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig BODY_KEY], encodedProductCodeValue];
        queryParameters = [[queryParameters stringByAppendingString:productCodeParameter] mutableCopy];
    }
    
    NSDictionary * visilabsParameters = [VisilabsPersistentTargetManager getParameters] ;
    
    if(visilabsParameters)
    {
        for (NSString *key in [visilabsParameters allKeys])
        {
            NSString *value = [visilabsParameters objectForKey:key];
            if (value && [value length] > 0)
            {
                NSString* encodedValue = [[Visilabs callAPI] urlEncode:value];
                NSString *parameter = [NSString stringWithFormat:@"&%@=%@", key, encodedValue];
                queryParameters = [[queryParameters stringByAppendingString:parameter] mutableCopy];
            }
        }
    }
    return [NSString stringWithString:queryParameters];
}


//- (NSString *)getArgsAsQueryString {
//    
//    __block NSString *qs = @"";
//    __block bool first = YES;
//    if (_args && [_args count] > 0) {
//        
//        [_args enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//            NSString *format = first ? @"%@=%@" : @"&%@=%@";
//            if (first) {
//                first = NO;
//            }
//            NSString *str = [NSString stringWithFormat:format, key, obj];
//            qs = [qs stringByAppendingString:str];
//        }];
//    }
//    return qs;
//}

//- (NSDictionary *)headers {
//    return nil;
//    __block NSMutableDictionary *defaultHeaders =
//    [NSMutableDictionary dictionaryWithDictionary:[Visilabs getDefaultParamsAsHeaders]];
//    if (nil != _headers) {
//        [_headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//            defaultHeaders[key] = obj;
//        }];
//    }
//    return defaultHeaders;
//}

@end
