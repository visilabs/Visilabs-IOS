//
//  VisilabsGeofenceRequest.m
//  Visilabs-IOS
//
//  Created by Visilabs on 10.08.2016.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsGeofenceRequest.h"
#import "Visilabs.h"
#import "VisilabsDefines.h"
#import "VisilabsPersistentTargetManager.h"

@implementation VisilabsGeofenceRequest

- (NSURL *)buildURL {
    @synchronized(self)
    {
        NSMutableString *geofenceURL = [[[Visilabs callAPI] geofenceURL] mutableCopy];
        NSString *queryParameters =[self getParametersAsQueryString];
        geofenceURL = [[geofenceURL stringByAppendingString:queryParameters] mutableCopy];
        DLog(@"Geofence Request url is %@", geofenceURL);
        NSURL *uri = [[NSURL alloc] initWithString:geofenceURL];
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
    
    if([self action] && [[self action] length] > 0)
    {
        NSString* encodedActIDValue = [[Visilabs callAPI] urlEncode:[self action]];
        NSString *actIDParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig ACT_KEY], encodedActIDValue];
        queryParameters = [[queryParameters stringByAppendingString:actIDParameter] mutableCopy];
    }
    
    if([self actionID] && [[self actionID] length] > 0)
    {
        NSString* encodedActIDValue = [[Visilabs callAPI] urlEncode:[self actionID]];
        NSString *actIDParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig ACT_ID_KEY], encodedActIDValue];
        queryParameters = [[queryParameters stringByAppendingString:actIDParameter] mutableCopy];
    }
    
    if([[Visilabs callAPI] tokenID] != nil &&  ![[[Visilabs callAPI] tokenID] isEqual: @""])
    {
        NSString* encodedTokenValue = [[Visilabs callAPI] urlEncode:[[Visilabs callAPI] tokenID]];
        NSString *tokenParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig TOKENID_KEY], encodedTokenValue];
        queryParameters = [[queryParameters stringByAppendingString:tokenParameter] mutableCopy];
    }
    if([[Visilabs callAPI] appID] != nil &&  ![[[Visilabs callAPI] appID] isEqual: @""])
    {
        NSString* encodedAppValue = [[Visilabs callAPI] urlEncode:[[Visilabs callAPI] appID]];
        NSString *appParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig APPID_KEY], encodedAppValue];
        queryParameters = [[queryParameters stringByAppendingString:appParameter] mutableCopy];
    }
    
    
    if(self.lastKnownLatitude > 0)
    {
        NSString* encodedLatitudeValue = [NSString stringWithFormat:@"%.013f", self.lastKnownLatitude];
        NSString *latitudeParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig LATITUDE_KEY], encodedLatitudeValue];
        queryParameters = [[queryParameters stringByAppendingString:latitudeParameter] mutableCopy];
    }
    
    if(self.lastKnownLongitude > 0)
    {
        NSString* encodedLongitudeValue = [NSString stringWithFormat:@"%.013f", self.lastKnownLongitude];
        NSString *longitudeParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig LONGITUDE_KEY], encodedLongitudeValue];
        queryParameters = [[queryParameters stringByAppendingString:longitudeParameter] mutableCopy];
    }
    
    NSString *appParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig APPID_KEY], @"IOS"];
    queryParameters = [[queryParameters stringByAppendingString:appParameter] mutableCopy];
    
    
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

@end
