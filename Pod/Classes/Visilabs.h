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


/*!
 @class
 Visilabs SDK.
 
 @abstract
 SDK for Visilabs Analytics and Target modules.
 */

@interface Visilabs : NSObject


@property (nonatomic, strong) NSString *actionURL;
@property (nonatomic, strong) NSString *targetURL;
@property (nonatomic, strong) NSString *organizationID;
@property (nonatomic, strong) NSString *siteID;
@property (nonatomic, strong) NSString *cookieID;
@property (nonatomic, strong) NSString *exVisitorID;

@property (nonatomic) BOOL isOnline;


/*!
 @property
 
 @abstract
 Controls whether to automatically check for notifications for the
 currently identified user after Visilabs logger request.
 
 @discussion
 Defaults to YES.
 */
@property (atomic) BOOL checkForNotificationsOnLoggerRequest;

/*!
 @property
 
 @abstract
 Determines the time, in seconds, that a mini notification will remain on
 the screen before automatically hiding itself.
 
 @discussion
 Defaults to 10.0.
 */
@property (atomic) CGFloat miniNotificationPresentationTime;

/*!
 @property
 
 @abstract
 If set, determines the background color of mini notifications.
 
 @discussion
 If this isn't set, we default to either the color of the UINavigationBar of the top
 UINavigationController that is showing when the notification is presented, the
 UINavigationBar default color for the app or the UITabBar default color.
 */
@property (atomic) UIColor* miniNotificationBackgroundColor;

/*!
 @method
 
 @abstract
 Shows a notification if one is available.
 
 @discussion
 You do not need to call this method on the main thread.
 */
- (void)showNotification:(NSString *)pageName;





- (NSString *)urlEncode:(NSString *)prior;

- (VisilabsTargetRequest *)buildTargetRequest:(NSString *)zoneID withProductCode:(NSString *)productCode;

+(Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel;

+(Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds ;

+(Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withTargetURL: (NSString *) targetURL ;

+(Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withRESTURL:(NSString *)RESTURL  withEncryptedDataSource:(NSString *)encryptedDataSource;

+ (Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withTargetURL:(NSString *)targetURL withActionURL:(NSString *)actionURL;

+(Visilabs *) callAPI ;

- (void)customEvent:(NSString *)pageName withProperties:(NSMutableDictionary *)properties;
- (void)login:(NSString *)exVisitorID;
- (void)signUp:(NSString *)exVisitorID;
- (void)login:(NSString *)exVisitorID withProperties:(NSMutableDictionary *)properties;
- (void)signUp:(NSString *)exVisitorID withProperties:(NSMutableDictionary *)properties;
- (NSString *)getPushURL:(NSString *)source withCampaign:(NSString *)campaign withMedium:(NSString *)medium withContent:(NSString *)content;


@end