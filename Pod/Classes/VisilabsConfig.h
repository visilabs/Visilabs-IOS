//
//  VisilabsConfig.h
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VisilabsConfig : NSObject

+ (NSArray *)visilabsParameters;

+ (NSString *) ORGANIZATIONID_KEY;
+ (NSString *) SITEID_KEY;
+ (NSString *) COOKIEID_KEY;
+ (NSString *) EXVISITORID_KEY;
+ (NSString *) ZONE_ID_KEY;
+ (NSString *) BODY_KEY;

+ (NSString *) LATITUDE_KEY;
+ (NSString *) LONGITUDE_KEY;

+ (NSString *) ACT_ID_KEY;
+ (NSString *) ACT_KEY;

+ (NSString *) TOKENID_KEY;
+ (NSString *) APPID_KEY;


+ (NSString *) LOGGER_URL;
+ (NSString *) REAL_TIME_URL;
+ (NSString *) LOAD_BALANCE_PREFIX;
+ (NSString *) OM_3_KEY;


+ (NSString *) FILTER_KEY;
+ (NSString *) APIVER_KEY;

+ (NSString *) GEO_ID_KEY;

+ (NSString *) TRIGGER_EVENT_KEY;

@end
