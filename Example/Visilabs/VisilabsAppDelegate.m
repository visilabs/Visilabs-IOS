//
//  VisilabsAppDelegate.m
//  Visilabs
//
//  Created by visilabs on 12/15/2015.
//  Copyright (c) 2015 visilabs. All rights reserved.
//

#import "VisilabsAppDelegate.h"

@implementation VisilabsAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //NSString * euromsgmobilappSiteID = @"482B67724F524B5A6353633D";
    //NSString * euromsgmobilappDataSource = @"euromsgmobilapp";
    
    /*
    NSString * visilabsDemoOID = @"53444A2B4B5071322F50303D";
    NSString * visilabsDemoSiteID = @"515977535854504E506E413D";
    NSString * visilabsDemoDataSource = @"mrhp";
    */
    
    NSString * visilabsNewOID = @"53444A2B4B5071322F50303D";
    NSString * visilabsNewSiteID = @"362F714E306C756B2B37593D";
    NSString * visilabsNewDataSource = @"visilabsnew";
    
    [Visilabs createAPI:visilabsNewOID withSiteID:visilabsNewSiteID withSegmentURL:@"http://lgr.visilabs.net" withDataSource:visilabsNewDataSource withRealTimeURL:@"http://rt.visilabs.net" withChannel:@"IOS" withRequestTimeout:30 withTargetURL:@"http://s.visilabs.net/json" withActionURL:@"http://s.visilabs.net/actjson"];
    // Override point for customization after application launch.
    
    [Visilabs callAPI].checkForNotificationsOnLoggerRequest = NO;
    
    return YES;
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

@end
