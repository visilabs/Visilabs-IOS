//
//  VisilabsGeofenceApp.m
//  Pods
//
//  Created by Visilabs on 12.08.2016.
//
//

#import "VisilabsGeofenceApp.h"

#import "VisilabsGeofenceInterceptor.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

#define SETTING_UTC_OFFSET                  @"SETTING_UTC_OFFSET"  //key for local saved utc offset value

#define APPKEY_KEY                          @"APPKEY_KEY" //key for store "app key", next time if try to read appKey before register, read from this one.
#define INSTALL_SUID_KEY                    @"INSTALL_SUID_KEY"

#define ENTER_PAGE_HISTORY                  @"ENTER_PAGE_HISTORY"  //key for record entered page history. It's set when enter a page and cleared when send exit log except go BG.
#define ENTERBAK_PAGE_HISTORY               @"ENTERBAK_PAGE_HISTORY" //key for record entered page history as backup. It's set as backup in case ENTER_PAGE_HISTORY not set in canceled pop up.
#define EXIT_PAGE_HISTORY                   @"EXIT_PAGE_HISTORY"  //key for record send exit log history. It's set when send exit log and cleared when send enter log. This is to avoid send duplicated exit log.

#define ADS_IDENTIFIER                      @"ADS_IDENTIFIER" //user pass in advertising identifier

#define SPOTLIGHT_DEEPLINKING_MAPPING      @"SPOTLIGHT_DEEPLINKING_MAPPING" //key for spotlight identifier to deeplinking mappig

@interface SHViewActivity : NSObject

@property (nonatomic, strong) NSString *viewName;
@property (nonatomic, strong) NSDate *enterTime;
@property (nonatomic, strong) NSDate *exitTime;
@property (nonatomic) double duration;
@property (nonatomic) BOOL enterBg;

@end

@implementation SHViewActivity

- (id)initWithViewName:(NSString *)viewName
{
    if (self = [super init])
    {
        self.viewName = viewName;
        self.enterTime = [NSDate date];
    }
    return self;
}

- (NSString *)serializeToString
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:self.viewName forKey:@"page"];
    [dict setObject:@(self.duration) forKey:@"duration"];
    [dict setObject:@(self.enterBg) forKey:@"bg"];
    return nil;
}

@end

@interface VisilabsGeofenceApp ()

@property (nonatomic) BOOL isBridgeInitCalled;
@property (nonatomic) BOOL isRegisterInstallForAppCalled;
@property (nonatomic) BOOL isFinishLaunchOptionCalled;

@property (nonatomic, strong) SHLogger *innerLogger;

@property (nonatomic, strong) NSOperationQueue *backgroundQueue;

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)backgroundTask;


- (void)setupNotifications;
- (void)applicationDidFinishLaunchingNotificationHandler:(NSNotification *)notification;
- (void)applicationWillResignActiveNotificationHandler:(NSNotification *)notification;
- (void)applicationDidEnterBackgroundNotificationHandler:(NSNotification *)notification;
- (void)applicationWillEnterForegroundNotificationHandler:(NSNotification *)notification;
- (void)applicationDidBecomeActiveNotificationHandler:(NSNotification *)notification;
- (void)applicationWillTerminateNotificationHandler:(NSNotification *)notification;
- (void)applicationDidReceiveMemoryWarningNotificationHandler:(NSNotification *)notification;
- (void)appStatusChange:(NSNotification *)notification;
+ (void)delaySendLaunchOptions:(NSNotification *)notification;

//sh_utc_offset update
- (void)checkUtcOffsetUpdate;  //Check utc_offset: if not logged before or changed, log it immediately.
- (void)timeZoneChangeNotificationHandler:(NSNotification *)notification;  //Notification handler called when time zone change


//Log enter/exit page.
@property (nonatomic, strong) SHViewActivity *currentView;
- (void)shNotifyPageEnter:(NSString *)page sendEnter:(BOOL)doEnter sendExit:(BOOL)doExit;
- (void)shNotifyPageExit:(NSString *)page clearEnterHistory:(BOOL)needClear logCompleteView:(BOOL)logComplete;

//For test purpose, check both Object-C style NSAssert and C style assert in SDK. It's hidden, not visible to public.
- (void)checkAssert;

//Auto integrate app delegate
@property (nonatomic, strong) VisilabsGeofenceInterceptor *appDelegateInterceptor; //interceptor for handling AppDelegate automatically integration.
@property (nonatomic, strong) id<UIApplicationDelegate> originalAppDelegate; //strong pointer to keep original customer's AppDelegate, otherwise after switch to interceptor it's null.


- (void)submitFriendlyNames;

@end

@implementation VisilabsGeofenceApp


#pragma mark - life cycle

+ (void)load
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(delaySendLaunchOptions:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)delaySendLaunchOptions:(NSNotification *)notification
{
    double delayInSeconds = 2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                   {
                       [[NSNotificationCenter defaultCenter] postNotificationName:@"VisilabsDelayLaunchOptionsNotification" object:notification.object userInfo:[notification.userInfo copy]];
                   });
}

+ (VisilabsGeofenceApp *)sharedInstance
{
    static VisilabsGeofenceApp *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      instance = [[VisilabsGeofenceApp alloc] init];
                  });
    if (!instance.isBridgeInitCalled)
    {
        instance.isBridgeInitCalled = YES;
#pragma GCC diagnostic push
#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wundeclared-selector"
        

        Class geofenceBridge = NSClassFromString(@"VisilabsGeofenceBridge");
        NSLog(@"Bridge for geofence: %@.", geofenceBridge);
        if (geofenceBridge)
        {
            [[NSNotificationCenter defaultCenter] addObserver:geofenceBridge selector:@selector(bridgeHandler:) name:SH_InitBridge_Notification object:nil];
        }
#pragma GCC diagnostic pop
#pragma clang diagnostic pop
        [[NSNotificationCenter defaultCenter] postNotificationName:SH_InitBridge_Notification object:nil];
        
        //TODO: added by egemen. normally calls another methpd
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_CreateLocationManager" object:nil];
    }
    
    return instance;
}

- (id)init
{
    if (self = [super init])
    {
        self.isBridgeInitCalled = NO;
        self.isRegisterInstallForAppCalled = NO;
        self.isFinishLaunchOptionCalled = NO;
        [[NSUserDefaults standardUserDefaults] setObject:@(0) forKey:SH_GEOLOCATION_LAT];
        [[NSUserDefaults standardUserDefaults] setObject:@(0) forKey:SH_GEOLOCATION_LNG];
        [[NSUserDefaults standardUserDefaults] setObject:@(0) forKey:SH_BEACON_BLUETOOTH];
        [[NSUserDefaults standardUserDefaults] setObject:@(3) forKey:SH_BEACON_iBEACON];
        [[NSUserDefaults standardUserDefaults] synchronize];
        //Then continue normal code.
        self.isDebugMode = NO;
        self.backgroundQueue = [[NSOperationQueue alloc] init];
        self.backgroundQueue.maxConcurrentOperationCount = 1;
        self.install_semaphore = dispatch_semaphore_create(1);  //happen in sequence
   
        
        self.autoIntegrateAppDelegate = YES;
        [self setupNotifications]; //move early so that Phonegap can handle remote notification in appDidFinishLaunching.
    }
    return self;
}

- (void)registerInstallForApp:(NSString *)appKey withDebugMode:(BOOL)isDebugMode
{
    if (self.isRegisterInstallForAppCalled)
    {
        return;
    }
    self.isRegisterInstallForAppCalled = YES;
    
    self.isDebugMode = isDebugMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_CreateLocationManager" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_CrashBridge_CreateObject" object:nil];


}

- (void)registerInstallForApp:(NSString *)appKey withDebugMode:(BOOL)isDebugMode withiTunesId:(NSString *)iTunesId
{
    return;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - properties

- (NSString *)appKey
{
    return _appKey;
}

- (void)setDefaultStartingUrl:(NSString *)defaultUrl
{
}

- (NSString *)itunesAppId
{
    return nil;
}

- (void)setItunesAppId:(NSString *)itunesAppId
{
    return;
}

- (NSString *)clientVersion
{
    return [NSString stringWithFormat:@"%@ (%@)", [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"], [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]];
}

- (NSString *)version
{
    return @"1.8.2";
}



#pragma mark - public functions


- (void)shRegularTask:(void (^)(UIBackgroundFetchResult))completionHandler needComplete:(BOOL)needComplete
{
    BOOL needHeartbeatLog = YES;
    NSObject *lastPostHeartbeatLogsVal = [[NSUserDefaults standardUserDefaults] objectForKey:REGULAR_HEARTBEAT_LOGTIME];
    if (lastPostHeartbeatLogsVal != nil && [lastPostHeartbeatLogsVal isKindOfClass:[NSNumber class]])
    {
        NSTimeInterval lastPostHeartbeatLogs = [(NSNumber *)lastPostHeartbeatLogsVal doubleValue];
        if ([[NSDate date] timeIntervalSinceReferenceDate] - lastPostHeartbeatLogs < 6*60*60) //heartbeat time interval is 6 hours
        {
            needHeartbeatLog = NO;
        }
    }
    Class locationBridge = NSClassFromString(@"SHLocationBridge");
    if (locationBridge) //consider sending more location logline 19.
    {
        NSMutableDictionary *dictUserInfo = [NSMutableDictionary dictionary];
        dictUserInfo[@"needHeartbeatLog"] = @(needHeartbeatLog);
        dictUserInfo[@"needComplete"] = @(needComplete);
        if (completionHandler)
        {
            dictUserInfo[@"completionHandler"] = completionHandler;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_RegularTask" object:nil userInfo:dictUserInfo];
    }
    else
    {
        if (!needHeartbeatLog) //nothing to do
        {
            if (needComplete && completionHandler != nil)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(UIBackgroundFetchResultNewData);
                });
            }
        }
        else
        {
            
        }
    }
}

- (BOOL)openURL:(NSURL *)url
{

    
    return NO;
}

- (void)setAdvertisingIdentifier:(NSString *)advertisingIdentifier
{
    return;
}

- (NSString *)advertisingIdentifier
{
    return nil;
    return [[NSUserDefaults standardUserDefaults] objectForKey:ADS_IDENTIFIER];
}

#pragma mark - permission

- (BOOL)launchSystemPreferenceSettings
{
    if (&UIApplicationOpenSettingsURLString != NULL)
    {
        NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:appSettings];
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - application system notification handler

- (void)applicationDidFinishLaunchingNotificationHandler:(NSNotification *)notification
{
    if (self.isFinishLaunchOptionCalled)
    {
        return;
    }
    self.isFinishLaunchOptionCalled = YES;
    
    BOOL isFromDelayLaunch = [notification.name isEqualToString:@"VisilabsDelayLaunchOptionsNotification"];
    NSDictionary *launchOptions = [notification userInfo];

    
    if (isFromDelayLaunch)
    {
        NSDictionary *notificationInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        if (notificationInfo != nil)
        {
            NSMutableDictionary *dictUserInfo = [NSMutableDictionary dictionary];
            dictUserInfo[@"payload"] = notificationInfo;
            dictUserInfo[@"needComplete"] = @(NO);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_PushBridge_ReceiveRemoteNotification" object:nil userInfo:dictUserInfo];
        }
    }
    
    if (launchOptions[UIApplicationLaunchOptionsLocationKey] != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_StartMonitorGeoLocation" object:nil];
    }
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground)
    {
        NSMutableDictionary *dictComment = [NSMutableDictionary dictionary];
        [dictComment setObject:@"App launch from not running." forKey:@"action"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_UpdateGeoLocation" object:nil];
        double lat = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_GEOLOCATION_LAT] doubleValue];
        double lng = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_GEOLOCATION_LNG] doubleValue];
        if (lat != 0 && lng != 0)
        {
            [dictComment setObject:@(lat) forKey:@"lat"];
            [dictComment setObject:@(lng) forKey:@"lng"];
        }
    }
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(setMinimumBackgroundFetchInterval:)])
    {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:30*60];
    }
    
}

- (void)applicationWillResignActiveNotificationHandler:(NSNotification *)notification
{
    DLog(@"Application will resignActive with info: %@.", notification.userInfo);
}

- (void)applicationDidEnterBackgroundNotificationHandler:(NSNotification *)notification
{
    DLog(@"Application did enter background with info: %@", notification.userInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_StartMonitorGeoLocation" object:nil];
    __block UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                                                         {
                                                             [self endBackgroundTask:backgroundTask];
                                                         }];
    __block NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^
                                    {
                                        if (!op.isCancelled)
                                        {
                                            NSMutableDictionary *dictComment = [NSMutableDictionary dictionary];
                                            [dictComment setObject:@"App to BG." forKey:@"action"];
                                            [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_UpdateGeoLocation" object:nil];
                                            double lat = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_GEOLOCATION_LAT] doubleValue];
                                            double lng = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_GEOLOCATION_LNG] doubleValue];
                                            if (lat != 0 && lng != 0)
                                            {
                                                [dictComment setObject:@(lat) forKey:@"lat"];
                                                [dictComment setObject:@(lng) forKey:@"lng"];
                                            }

                                        }
                                        else
                                        {
                                            [self endBackgroundTask:backgroundTask];
                                        }
                                    }];
    [self.backgroundQueue addOperation:op];
}

- (void)applicationWillEnterForegroundNotificationHandler:(NSNotification *)notification
{

    DLog(@"Application will enter foreground with info: %@", notification.userInfo);
    
    NSMutableDictionary *dictComment = [NSMutableDictionary dictionary];
    [dictComment setObject:@"App opened from BG." forKey:@"action"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_UpdateGeoLocation" object:nil];
    
    double lat = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_GEOLOCATION_LAT] doubleValue];
    double lng = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_GEOLOCATION_LNG] doubleValue];
    if (lat != 0 && lng != 0)
    {
        [dictComment setObject:@(lat) forKey:@"lat"];
        [dictComment setObject:@(lng) forKey:@"lng"];
    }

}


- (void)applicationDidBecomeActiveNotificationHandler:(NSNotification *)notification
{

    DLog(@"Application did become active with info: %@", notification.userInfo);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_StartMonitorGeoLocation" object:nil];

    [self shRegularTask:nil needComplete:NO];
}

- (void)applicationWillTerminateNotificationHandler:(NSNotification *)notification
{
    DLog(@"Application will terminate with info: %@", notification.userInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_StartMonitorGeoLocation" object:nil];
}

- (void)applicationDidReceiveMemoryWarningNotificationHandler:(NSNotification *)notification
{
    DLog(@"Visilabs Received memory warning");
}

- (void)appStatusChange:(NSNotification *)notification
{
    return;
}

- (void)timeZoneChangeNotificationHandler:(NSNotification *)notification
{
    [self checkUtcOffsetUpdate];
}

#pragma mark - UIAppDelegate auto integration

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings  //since iOS 8.0
{
    NSMutableDictionary *dictUserInfo = [NSMutableDictionary dictionary];
    if (notificationSettings != nil)
    {
        dictUserInfo[@"notificationSettings"] = notificationSettings;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_PushBridge_DidRegisterUserNotification" object:nil userInfo:dictUserInfo];
    
    if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:didRegisterUserNotificationSettings:)])
    {
        [self.appDelegateInterceptor.secondResponder application:application didRegisterUserNotificationSettings:notificationSettings];
    }
    
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSMutableDictionary *dictUserInfo = [NSMutableDictionary dictionary];
    if (deviceToken != nil)
    {
        dictUserInfo[@"token"] = deviceToken;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_PushBridge_ReceiveToken_Notification" object:nil userInfo:dictUserInfo];
    
    if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)])
    {
        [self.appDelegateInterceptor.secondResponder application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

//called when notification arrives and:
//1. App in FG, directly call this.
//2. App in BG notification banner show, click the banner (not the button) and call this.
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    
    if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:didReceiveRemoteNotification:)])
    {
        [self.appDelegateInterceptor.secondResponder application:application didReceiveRemoteNotification:userInfo];
    }
    BOOL customerAppResponse = [self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
    
    
    
    
    NSMutableDictionary *dictUserInfo = [NSMutableDictionary dictionary];
    if (userInfo != nil)
    {
        dictUserInfo[@"payload"] = userInfo;
    }
    dictUserInfo[@"needComplete"] = @(!customerAppResponse);
    if (completionHandler)
    {
        dictUserInfo[@"fetchCompletionHandler"] = completionHandler;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_PushBridge_ReceiveRemoteNotification" object:nil userInfo:dictUserInfo];
    if (customerAppResponse)
    {
        [self.appDelegateInterceptor.secondResponder application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
    
}

//called when notification arrives and:
//1. App in BG notification bannder show, pull down and click the button can call this.
//2. NOT called when App in FG.
//3. NOT called when click notification banner directly.
//This delegate callback not mixed with above `didReceiveRemoteNotification`.
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
    BOOL customerAppResponse = [self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)];
    NSMutableDictionary *dictUserInfo = [NSMutableDictionary dictionary];
    if (userInfo != nil)
    {
        dictUserInfo[@"payload"] = userInfo;
    }
    if (identifier != nil)
    {
        dictUserInfo[@"actionid"] = identifier;
    }
    dictUserInfo[@"needComplete"] = @(!customerAppResponse);
    if (completionHandler)
    {
        dictUserInfo[@"completionHandler"] = completionHandler;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_PushBridge_HandleRemoteActionButton" object:nil userInfo:dictUserInfo];
    if (customerAppResponse)
    {
        [self.appDelegateInterceptor.secondResponder application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSMutableDictionary *dictUserInfo = [NSMutableDictionary dictionary];
    if (notification != nil)
    {
        dictUserInfo[@"notification"] = notification;
    }
    dictUserInfo[@"needComplete"] = @(YES);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_PushBridge_ReceiveLocalNotification" object:nil userInfo:dictUserInfo];
    if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:didReceiveLocalNotification:)])
    {
        [self.appDelegateInterceptor.secondResponder application:application didReceiveLocalNotification:notification];
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler
{
    BOOL customerAppResponse = [self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:)];
    NSMutableDictionary *dictUserInfo = [NSMutableDictionary dictionary];
    if (notification != nil)
    {
        dictUserInfo[@"notification"] = notification;
    }
    if (identifier != nil)
    {
        dictUserInfo[@"actionid"] = identifier;
    }
    dictUserInfo[@"needComplete"] = @(!customerAppResponse);
    if (completionHandler)
    {
        dictUserInfo[@"completionHandler"] = completionHandler;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_PushBridge_HandleLocalActionButton" object:nil userInfo:dictUserInfo];
    if (customerAppResponse)
    {
        [self.appDelegateInterceptor.secondResponder application:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    BOOL customerAppResponse = [self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:performFetchWithCompletionHandler:)];
    if (customerAppResponse)
    {
        [self.appDelegateInterceptor.secondResponder application:application performFetchWithCompletionHandler:completionHandler];
    }
}

//since iOS 9 uses this delegate callback, and `- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation` is not called when this new delegate present.
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    BOOL customerHandled = NO;
    if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:openURL:options:)])
    {
        customerHandled = [self.appDelegateInterceptor.secondResponder application:app openURL:url options:options];
    }
    if (!customerHandled)
    {
        if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) //try old style handle
        {
            customerHandled = [self.appDelegateInterceptor.secondResponder application:app openURL:url sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey] annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
        }
    }
    if (!customerHandled)
    {
        if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:handleOpenURL:)]) //try old style handle
        {
            customerHandled = [self.appDelegateInterceptor.secondResponder application:app handleOpenURL:url];
        }
    }
    
    
    return NO;

}

//before iOS 9 still use this delegate.
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    BOOL customerHandled = NO;
    if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)])
    {
        customerHandled = [self.appDelegateInterceptor.secondResponder application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    if (!customerHandled)
    {
        if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:handleOpenURL:)]) //try old style handle
        {
            customerHandled = [self.appDelegateInterceptor.secondResponder application:application handleOpenURL:url];
        }
    }
    
    return NO;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler
{
    BOOL customerHandled = NO;
    if ([self.appDelegateInterceptor.secondResponder respondsToSelector:@selector(application:continueUserActivity:restorationHandler:)])
    {
        customerHandled = [self.appDelegateInterceptor.secondResponder application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    
    return NO;
}

#pragma mark - private functions

- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunchingNotificationHandler:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunchingNotificationHandler:) name:@"VisilabsDelayLaunchOptionsNotification" object:nil]; //handle both direct send and delay send
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotificationHandler:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotificationHandler:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotificationHandler:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotificationHandler:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminateNotificationHandler:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveMemoryWarningNotificationHandler:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeZoneChangeNotificationHandler:) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appStatusChange:) name:@"SHAppStatusChangeNotification" object:nil];
}

- (void)checkUtcOffsetUpdate
{
    NSInteger offset = [[NSTimeZone localTimeZone] secondsFromGMT];
    BOOL needUpdateUtcOffset = YES;
    NSObject *utcoffsetVal = [[NSUserDefaults standardUserDefaults] objectForKey:SETTING_UTC_OFFSET];
    if (utcoffsetVal != nil && [utcoffsetVal isKindOfClass:[NSNumber class]])
    {
        int utcOffsetLocal = [(NSNumber *)utcoffsetVal intValue];
        if (utcOffsetLocal == offset / 60)
        {
            needUpdateUtcOffset = NO;
        }
    }
    if (needUpdateUtcOffset)
    {
        __block UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                                                             {
                                                                 [self endBackgroundTask:backgroundTask];
                                                             }];
        __block NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^
                                        {
                                            [self endBackgroundTask:backgroundTask];
                                        }];
        [self.backgroundQueue addOperation:op];
    }
}


- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)backgroundTask
{
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
    backgroundTask = UIBackgroundTaskInvalid;
}

- (void)shNotifyPageEnter:(NSString *)page sendEnter:(BOOL)doEnter sendExit:(BOOL)doExit
{
    if (page == nil || page.length == 0)
    {
        NSAssert(doEnter, @"Enter without page should used for App go to FG only, with doEnter = YES");
        NSAssert(!doExit, @"Enter without page should used for App go to FG only, with doExit = NO");
        page = [[NSUserDefaults standardUserDefaults] objectForKey:ENTER_PAGE_HISTORY];
    }
    if (doExit)
    {
        NSString *previousEnterPage = [[NSUserDefaults standardUserDefaults] objectForKey:ENTER_PAGE_HISTORY];
        if (previousEnterPage != nil && previousEnterPage.length > 0)
        {
            NSString *previousExitPage = [[NSUserDefaults standardUserDefaults] objectForKey:EXIT_PAGE_HISTORY];
            BOOL multipleBGTerminal = NO;
            if ([previousEnterPage compare:page options:NSCaseInsensitiveSearch] == NSOrderedSame && previousExitPage != nil && previousExitPage.length > 0)
            {
                multipleBGTerminal = YES;
            }
            if (!multipleBGTerminal)
            {
                [self shNotifyPageExit:previousEnterPage clearEnterHistory:YES logCompleteView:NO];
            }
        }
    }
    if (page != nil && page.length > 0)
    {
    }
}

- (void)shNotifyPageExit:(NSString *)page clearEnterHistory:(BOOL)needClear logCompleteView:(BOOL)logComplete
{
    BOOL isEnterBg = (page == nil || page.length == 0);
    if (page == nil || page.length == 0)
    {
        NSAssert(!needClear, @"Exit without page should used for App go to BG only, with needClear = NO");
        page = [[NSUserDefaults standardUserDefaults] objectForKey:ENTER_PAGE_HISTORY]; //for App go BG and log exit
    }
    if (needClear)
    {
        NSAssert(page != nil && page.length > 0, @"Try to really exit a page without page name. Stop now.");
    }
    if (page != nil && page.length > 0)
    {
        NSString *previousExitPage = [[NSUserDefaults standardUserDefaults] objectForKey:EXIT_PAGE_HISTORY];
        if (previousExitPage != nil && previousExitPage.length > 0)
        {
            NSAssert([previousExitPage compare:page options:NSCaseInsensitiveSearch] == NSOrderedSame, @"Try to send exit page (%@) different from history (%@).", page, previousExitPage);
            if ([previousExitPage compare:page options:NSCaseInsensitiveSearch] == NSOrderedSame)
            {
                return;
            }
        }
        if (logComplete)
        {
            NSAssert(self.currentView != nil && [self.currentView.viewName isEqualToString:page], @"When complete enter (%@) different from exit (%@).", self.currentView.viewName, page);
            if (self.currentView != nil && [self.currentView.viewName isEqualToString:page])
            {
                self.currentView.exitTime = [NSDate date];
                self.currentView.duration = [self.currentView.exitTime timeIntervalSinceDate:self.currentView.enterTime];
                self.currentView.enterBg = isEnterBg;
            }
        }
        [[NSUserDefaults standardUserDefaults] setObject:page forKey:EXIT_PAGE_HISTORY]; //remember this.
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (needClear)
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:ENTER_PAGE_HISTORY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)submitFriendlyNames
{
    return;
}

- (void)checkAssert
{
    NSAssert(NO, @"Crash intentionally: NSAssert in SDK.");
    NSAssert1(NO, @"Crash intentionally: NSAssert1 in SDK: %@.", @"param1");
    NSAssert2(NO, @"Crash intentionally: NSAssert2 in SDK, %@, %@.", @"param1", @"param2");
    NSAssert3(NO, @"Crash intentionally: NSAssert3 in SDK, %@, %@, %@.", @"param1", @"param2", @"param3");
    NSAssert4(NO, @"Crash intentionally: NSAssert4 in SDK, %@, %@, %@, %@.", @"param1", @"param2", @"param3", @"param4");
    NSAssert5(NO, @"Crash intentionally: NSAssert5 in SDK, %@, %@, %@, %@, %@.", @"param1", @"param2", @"param3", @"param4", @"param5");
    assert(NO && @"Crash intentionally: assert in SDK.");
}

@end

@interface VisilabsGeofenceApp (LoggerExt_private)

- (BOOL)checkTagValue:(NSObject *)value forKey:(NSString *)key;
- (NSString *)checkTagKey:(NSString *)key;

@end

@implementation VisilabsGeofenceApp (LoggerExt)

#pragma mark - public functions

- (BOOL)tagCuid:(NSString *)uniqueId
{
    return [self tagString:uniqueId forKey:@"sh_cuid"];
}

- (BOOL)tagUserLanguage:(NSString *)language
{
    return [self tagString:language forKey:@"sh_language"];
}

- (BOOL)tagString:(NSObject *)value forKey:(NSString *)key
{

    return NO;
}

- (BOOL)tagNumeric:(double)value forKey:(NSString *)key
{
    return NO;
}

- (BOOL)tagDatetime:(NSDate *)value forKey:(NSString *)key
{

    return NO;
}

- (BOOL)removeTag:(NSString *)key
{
    return NO;
}

- (BOOL)incrementTag:(NSString *)key
{
    return [self incrementTag:1 forKey:key];
}

- (BOOL)incrementTag:(int)value forKey:(NSString *)key
{
    return NO;
}

#pragma mark - private functions

- (BOOL)checkTagValue:(NSObject *)value forKey:(NSString *)key
{
    if (key != nil && key.length > 0 && [key compare:@"sh_phone" options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        BOOL isValid = [value isKindOfClass:[NSString class]] && ((NSString *)value).length > 1 && [(NSString *)value hasPrefix:@"+"];
        if (isValid)
        {
            for (int i = 1; i < ((NSString *)value).length; i ++)
            {
                unichar charNumber = [(NSString *)value characterAtIndex:i];
                if (charNumber > '9' || charNumber < '0')
                {
                    isValid = NO;
                    break;
                }
            }
        }
        return isValid;
    }
    return YES;
}

- (NSString *)checkTagKey:(NSString *)key
{
    if (key.length > 30)
    {
        key = [key substringToIndex:30];
    }
    return key;
}

@end

@interface VisilabsGeofenceApp (InstallExt_private)

- (void)registerInstallWithHandler:(VisilabsCallbackHandler)handler;

@end

@implementation VisilabsGeofenceApp (InstallExt)

#pragma mark - public functions

-(void)registerOrUpdateInstallWithHandler:(VisilabsCallbackHandler)handler
{
    handler = [handler copy];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
                   {
                       NSAssert(![NSThread isMainThread], @"registerOrUpdateInstallWithHandler wait in main thread.");
                       if (![NSThread isMainThread])
                       {
                           dispatch_semaphore_wait(self.install_semaphore, DISPATCH_TIME_FOREVER);
                       }
                   });
}

NSString *SentInstall_AppKey = @"SentInstall_AppKey";
NSString *SentInstall_ClientVersion = @"SentInstall_ClientVersion";
NSString *SentInstall_ShVersion = @"SentInstall_ShVersion";
NSString *SentInstall_Mode = @"SentInstall_Mode";
NSString *SentInstall_Carrier = @"SentInstall_Carrier";
NSString *SentInstall_OSVersion = @"SentInstall_OSVersion";
NSString *SentInstall_IBeacon = @"SentInstall_IBeacon";

-(BOOL)checkInstallChangeForLaunch
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_UpdateiBeaconStatus" object:nil];

}

#pragma mark - private functions

-(void)registerInstallWithHandler:(VisilabsCallbackHandler)handler
{
    return;
}

@end
