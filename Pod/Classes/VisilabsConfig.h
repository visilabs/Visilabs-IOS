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

+ (NSString *) LOGGER_URL;
+ (NSString *) REAL_TIME_URL;
+ (NSString *) LOAD_BALANCE_PREFIX;
+ (NSString *) OM_3_KEY;

@end
