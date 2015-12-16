//
//  Visilabs.h
//  Visilabs-IOS
//
//  Created by Visilabs on 7.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VisilabsAction.h"
#import "VisilabsTargetRequest.h"
#import "VisilabsResponse.h"
#import "VisilabsJSON.h"

typedef NS_ENUM(NSInteger, VisilabsSDKNetworkErrorType) {
    VisilabsSDKNetworkOfflineErrorType = 1
};


@interface Visilabs : NSObject

@property (nonatomic, strong) NSString *targetURL;
@property (nonatomic, strong) NSString *organizationID;
@property (nonatomic, strong) NSString *siteID;
@property (nonatomic, strong) NSString *cookieID;
@property (nonatomic, strong) NSString *exVisitorID;

@property (nonatomic) BOOL isOnline;


- (NSString *)urlEncode:(NSString *)prior;

- (VisilabsTargetRequest *)buildTargetRequest:(NSString *)zoneID withProductCode:(NSString *)productCode;

+(Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel;

+(Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds ;

+(Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withTargetURL: (NSString *) targetURL ;

+(Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withRESTURL:(NSString *)RESTURL  withEncryptedDataSource:(NSString *)encryptedDataSource;

+(Visilabs *) callAPI ;

- (void)customEvent:(NSString *)pageName withProperties:(NSMutableDictionary *)properties;
- (void)login:(NSString *)exVisitorID;
- (void)signUp:(NSString *)exVisitorID;
- (void)login:(NSString *)exVisitorID withProperties:(NSMutableDictionary *)properties;
- (void)signUp:(NSString *)exVisitorID withProperties:(NSMutableDictionary *)properties;
- (NSString *)getPushURL:(NSString *)source withCampaign:(NSString *)campaign withMedium:(NSString *)medium withContent:(NSString *)content;


@end