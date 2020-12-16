//
//  VisilabsAppDelegate.m
//  Visilabs
//
//  Created by visilabs on 12/15/2015.
//  Copyright (c) 2015 visilabs. All rights reserved.
//

#import "VisilabsAppDelegate.h"
//#import "QGSdk.h"
//#import "EuroIOSFramework/EuroManager.h"


@implementation VisilabsAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    NSString * visilabsNewOID = @"676D325830564761676D453D";
    NSString * visilabsNewSiteID = @"356467332F6533766975593D";
    NSString * visilabsNewDataSource = @"visistore";
    


    
    NSString * geofenceURL = @"https://s.visilabs.net/geojson";
    NSString * targetURL = @"https://s.visilabs.net/json";
    NSString * actionURL = @"https://s.visilabs.net/actjson";
    
     [Visilabs createAPI:visilabsNewOID withSiteID:visilabsNewSiteID withSegmentURL:@"https://lgr.visilabs.net" withDataSource:visilabsNewDataSource withRealTimeURL:@"https://rt.visilabs.net" withChannel:@"IOS" withRequestTimeout:30 withTargetURL:targetURL withActionURL:actionURL withGeofenceURL:geofenceURL withGeofenceEnabled:YES
    withMaxGeofenceCount: 20];
    
    
    [[Visilabs callAPI] login:@"ogun.ozturk@euromsg.com" withProperties:nil];


    return YES;
}

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}
#endif

- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    NSString *tokenString = [[[deviceToken description] stringByTrimmingCharactersInSet:
                              [NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                             stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"Token: %@",tokenString);
    
    
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken");
    /*
    [[EuroManager sharedManager:@"VisilabsIOSDemoTest"] registerToken:deviceToken];
    [[EuroManager sharedManager:@"VisilabsIOSDemoTest"] synchronize];
     */
    
    
    
    [[Visilabs callAPI] login:@"egemengulkilik@gmail.com"];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:tokenString forKey:@"OM.sys.TokenID"];
    [dic setObject:@"VisilabsIOSDemo" forKey:@"OM.sys.AppID"];
    [[Visilabs callAPI] customEvent:@"RegisterToken" withProperties:dic];
    
}




- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Registration failed : %@",error.description);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"User Info Description: %@",userInfo.debugDescription);

    
}

- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //NSLog(@"didReceiveRemoteNotification : %@",userInfo);
    /*
    [[EuroManager sharedManager:@"VisilabsIOSDemoTest2"] handlePush:userInfo];
     */
}








- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//Called when a notification is delivered to a foreground app.
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    NSLog(@"User Info : %@",notification.request.content.userInfo);
    completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
}

//Called to let your app know which action was selected by the user for a given notification.
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    NSLog(@"User Info : %@",response.notification.request.content.userInfo);
    completionHandler();
}



@end
