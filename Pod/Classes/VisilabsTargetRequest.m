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
        //DLog(@"Request url is %@", targetURL);
        NSURL *uri = [[NSURL alloc] initWithString:targetURL];
        return uri;
    }
}

- (void)cleanParameters {
    if([self properties]){
        for(NSString *propKey in [[self properties] allKeys]){
            if(![propKey isEqual:[VisilabsConfig ORGANIZATIONID_KEY]] && ![propKey isEqual:[VisilabsConfig SITEID_KEY]]
               && ![propKey isEqual:[VisilabsConfig EXVISITORID_KEY]] && ![propKey isEqual:[VisilabsConfig COOKIEID_KEY]]
               && ![propKey isEqual:[VisilabsConfig ZONE_ID_KEY]] && ![propKey isEqual:[VisilabsConfig BODY_KEY]]
               && ![propKey isEqual:[VisilabsConfig TOKENID_KEY]] && ![propKey isEqual:[VisilabsConfig APPID_KEY]]
               && ![propKey isEqual:[VisilabsConfig APIVER_KEY]] && ![propKey isEqual:[VisilabsConfig FILTER_KEY]]){
                continue;
            }else{
                [[self properties] removeObjectForKey:propKey];
            }
        }
    }
}

- (NSString *)getFiltersQueryString:(NSArray<VisilabsTargetFilter *> *)filters{
    if(!filters){
        return nil;
    }else{
        NSError *writeError = nil;
        //NSMutableArray<VisilabsTargetFilterAbbreviated *> * abbreviatedFilters = [[NSMutableArray alloc] init];
        
        NSMutableArray *abbFilters = [[NSMutableArray alloc] init];
    
        for(VisilabsTargetFilter *propKey in filters){
            if(propKey){
                if(propKey.attribute && propKey.attribute != @"" && propKey.filterType && propKey.filterType != @"" &&
                   propKey.value && propKey.value != @"" ){
                    /*
                    VisilabsTargetFilterAbbreviated *abbreviatedFilter = [[VisilabsTargetFilterAbbreviated alloc] init];
                    abbreviatedFilter.attr = propKey.attribute;
                    abbreviatedFilter.ft = propKey.filterType;
                    abbreviatedFilter.fv = propKey.value;
                    [abbreviatedFilters addObject:abbreviatedFilter];
                     */
                    
                    NSMutableDictionary *abbFilter =  [[NSMutableDictionary alloc] init];
                    [abbFilter setObject:propKey.attribute forKey:@"attr"];
                    [abbFilter setObject:propKey.filterType forKey:@"ft"];
                    [abbFilter setObject:propKey.value forKey:@"fv"];
                    [abbFilters addObject:abbFilter];
                }
            }
        }
    
        if(abbFilters && abbFilters.count > 0){
            @try {
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:abbFilters options:0 error:&writeError];
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                NSLog(@"JSON Output: %@", jsonString);
                return jsonString;
            }@catch(NSException *exception) {
                NSLog(@"NSJSONSerialization Error Name: %@   Error Reason: %@", exception.name, exception.reason);
                return nil;
            }
        }else{
            return nil;
        }
    
        
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
    
    
    [self cleanParameters];
    
    NSString* filtersString = [self getFiltersQueryString:[self filters]];
    if(filtersString){
        NSString *filterParameter = [NSString stringWithFormat:@"&%@=%@", [VisilabsConfig FILTER_KEY], [[Visilabs callAPI] urlEncode:filtersString]];
        queryParameters = [[queryParameters stringByAppendingString:filterParameter] mutableCopy];
    }
    
    queryParameters = [[queryParameters stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", [VisilabsConfig APIVER_KEY], @"IOS"]] mutableCopy];
    
    if([self properties]){
        for (NSString *key in [[self properties] allKeys]){
            NSString *value = [[self properties] objectForKey:key];
            if (value && [value length] > 0)
            {
                NSString* encodedValue = [[Visilabs callAPI] urlEncode:value];
                NSString *parameter = [NSString stringWithFormat:@"&%@=%@", key, encodedValue];
                queryParameters = [[queryParameters stringByAppendingString:parameter] mutableCopy];
            }
        }
    }
    
    NSDictionary * visilabsParameters = [VisilabsPersistentTargetManager getParameters];
    
    if(visilabsParameters)
    {
        for (NSString *key in [visilabsParameters allKeys])
        {
            if([[self properties] objectForKey:key]){
                continue;
            }
            
            
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
