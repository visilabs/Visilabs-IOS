//
//  VisilabsGeofenceApp.h
//  Pods
//
//  Created by Visilabs on 12.08.2016.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VisilabsDefines.h"

@class SHLogger;

/**
 Callback to let customer App to handle deeplinking url.
 */
typedef void (^SHOpenUrlHandler)(NSURL *openUrl);

/**
 Singleton to access SHApp.
 */
#define VisiGeofence          [VisilabsGeofenceApp sharedInstance]


#define SH_InitBridge_Notification  @"SH_InitBridge_Notification"


@interface VisilabsGeofenceApp : NSObject<UIApplicationDelegate>

+ (VisilabsGeofenceApp *)sharedInstance;

- (void)registerInstallForApp:(NSString *)appKey withDebugMode:(BOOL)isDebugMode;


- (void)registerInstallForApp:(NSString *)appKey withDebugMode:(BOOL)isDebugMode withiTunesId:(NSString *)iTunesId;


@property (nonatomic, strong) NSString *appKey;


- (void)setDefaultStartingUrl:(NSString *)defaultUrl;


@property (nonatomic) BOOL isDebugMode;


@property (nonatomic, strong) NSString *itunesAppId;


@property (nonatomic, strong, readonly) NSString *clientVersion;


@property (nonatomic, strong, readonly) NSString *version;


@property (nonatomic, strong) dispatch_semaphore_t install_semaphore;

@property (nonatomic, strong) NSString *advertisingIdentifier;


@property (nonatomic) BOOL autoIntegrateAppDelegate;


@property (nonatomic, copy) SHOpenUrlHandler openUrlHandler;


@property (nonatomic, readonly, weak) SHLogger *logger;


- (void)shRegularTask:(void (^)(UIBackgroundFetchResult result))completionHandler needComplete:(BOOL)needComplete NS_AVAILABLE_IOS(7_0);

- (BOOL)openURL:(NSURL *)url;


- (BOOL)launchSystemPreferenceSettings NS_AVAILABLE_IOS(8_0);

- (void)indexSpotlightSearchForIdentifier:(NSString *)identifier forDeeplinking:(NSString *)deeplinking withSearchTitle:(NSString *)searchTitle withSearchDescription:(NSString *)searchDescription withThumbnail:(UIImage *)thumbnail withKeywords:(NSArray *)keywords NS_AVAILABLE_IOS(9_0);


- (void)deleteSpotlightItemsForIdentifiers:(NSArray *)arrayIdentifiers NS_AVAILABLE_IOS(9_0);


- (void)deleteAllSpotlightItems NS_AVAILABLE_IOS(9_0);

- (BOOL)continueUserActivity:(NSUserActivity *)userActivity NS_AVAILABLE_IOS(9_0);

@end

@interface VisilabsGeofenceApp (LoggerExt)

- (BOOL)tagCuid:(NSString *)uniqueId;

- (BOOL)tagUserLanguage:(NSString *)language;

- (BOOL)tagString:(NSObject *)value forKey:(NSString *)key;

- (BOOL)tagNumeric:(double)value forKey:(NSString *)key;

- (BOOL)tagDatetime:(NSDate *)value forKey:(NSString *)key;

- (BOOL)removeTag:(NSString *)key;

- (BOOL)incrementTag:(NSString *)key;

- (BOOL)incrementTag:(int)value forKey:(NSString *)key;

@end

@interface VisilabsGeofenceApp (InstallExt)

- (void)registerOrUpdateInstallWithHandler:(VisilabsCallbackHandler)handler;

- (BOOL)checkInstallChangeForLaunch;

@end
