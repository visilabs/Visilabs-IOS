//
//  Visilabs.m
//  Visilabs-IOS
//
//  Created by Visilabs on 7.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import <AdSupport/ASIdentifierManager.h>
#import <WebKit/WebKit.h>
#import "VisilabsReachability.h"
#import "Visilabs.h"
#import "VisilabsDefines.h"
#import "VisilabsParameter.h"
#import "VisilabsConfig.h"
#import "VisilabsPersistentTargetManager.h"
#import "VisilabsNotification.h"
#import "VisilabsNotificationViewController.h"
#import "UIView+VisilabsHelpers.h"
#import "VisilabsGeofenceApp.h"
#import "VisilabsGeofenceApp+Location.h"

static Visilabs * API = nil;


@interface NSString (CWAddition)
-(NSString*)stringBetweenString:(NSString*)start andString:(NSString*)end;
- (BOOL)containsString:(NSString *)string;
- (BOOL)containsString:(NSString *)string options:(NSStringCompareOptions)options;
@end

@implementation NSString (NSAddition)
-(NSString*)stringBetweenString:(NSString*)start andString:(NSString*)end {
    NSRange startRange = [self rangeOfString:start];
    if (startRange.location != NSNotFound) {
        NSRange targetRange;
        targetRange.location = startRange.location + startRange.length;
        targetRange.length = [self length] - targetRange.location;
        NSRange endRange = [self rangeOfString:end options:0 range:targetRange];
        if (endRange.location != NSNotFound) {
            targetRange.length = endRange.location - targetRange.location;
            return [self substringWithRange:targetRange];
        }
    }
    return nil;
}
- (BOOL)containsString:(NSString *)string
               options:(NSStringCompareOptions)options {
    NSRange rng = [self rangeOfString:string options:options];
    return rng.location != NSNotFound;
}
- (BOOL)containsString:(NSString *)string {
    return [self containsString:string options:0];
}
@end


@interface Visilabs()<VisilabsNotificationViewControllerDelegate>

@property (nonatomic, retain) NSString *segmentURL;
@property (nonatomic, retain) NSString *realTimeURL;
@property (nonatomic, retain) NSString *dataSource;
@property (nonatomic, retain) NSMutableArray *sendQueue;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSURLConnection *segmentConnection;
@property (nonatomic, readwrite) NSInteger failureStatus;
@property (nonatomic,retain) NSString *channel;
@property (nonatomic,retain) NSString *RESTURL;
@property (nonatomic, retain) NSString *encryptedDataSource;
@property (nonatomic, readwrite) NSInteger requestTimeout;
@property (nonatomic, retain) NSString *cookieIDArchiveKey ;
@property (nonatomic, retain) NSString *exVisitorIDArchiveKey ;
@property (nonatomic, retain) NSString *propertiesArchiveKey ;

@property (nonatomic, retain) NSString *tokenIDArchiveKey ;
@property (nonatomic, retain) NSString *appIDArchiveKey ;
@property (nonatomic, retain) NSString *userAgentArchiveKey ;

@property (nonatomic, retain) NSString *visitData;
@property (nonatomic, retain) NSString *visitorData;

@property (nonatomic, retain) NSString *identifierForAdvertising;

- (void) initAPI:(NSString *)oID withSiteID:(NSString*) sID withSegmentURL:(NSString *) sURL withDataSource:(NSString *) dSource withRealTimeURL:(NSString *)rURL withChannel:(NSString *)chan withRequestTimeout:(NSInteger)seconds  withRESTURL:(NSString *)restURL withEncryptedDataSource:(NSString *) eDataSource withTargetURL:(NSString *)tURL withActionURL:(NSString *)aURL withGeofenceURL:(NSString *)gURL withGeofenceEnabled:(BOOL) gEnabled  withMaxGeofenceCount:(NSInteger)maxGeofenceCount;
- (void) send;
- (NSString *)urlizeProps:(NSDictionary *)props;
- (void)setProperties:(NSDictionary *)properties;
- (void)clearExVisitorID;
- (void)setCookieID;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)setExVisitorIDToNull;

/*Notification Properties*/
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) id currentlyShowingNotification;
@property (nonatomic, strong) UIViewController *notificationViewController;
@property (nonatomic) BOOL notificationResponseCached;


@property (nonatomic, retain) NSString *loggerCookieKey;
@property (nonatomic, retain) NSString *loggerCookieValue;
@property (nonatomic, retain) NSString *realTimeCookieKey;
@property (nonatomic, retain) NSString *realTimeCookieValue;


@property (nonatomic, retain) NSString *loggerOM3rdCookieValue;
@property (nonatomic, retain) NSString *realTimeOM3rdCookieValue;

@property(nonatomic, strong) WKWebView *webView;

@end


@implementation Visilabs

@synthesize segmentURL;
@synthesize realTimeURL;
@synthesize dataSource;
@synthesize sendQueue;
@synthesize timer;
@synthesize segmentConnection;
@synthesize failureStatus;
@synthesize requestTimeout;
@synthesize RESTURL;
@synthesize encryptedDataSource;

static VisilabsReachability *reachability;


void dispatch_once_on_main_thread(dispatch_once_t *predicate, dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        dispatch_once(predicate, block);
    } else {
        if (DISPATCH_EXPECT(*predicate == 0L, NO)) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                dispatch_once(predicate, block);
            });
        }
    }
}

- (void)computeWebViewUserAgent {
    static dispatch_once_t onceToken;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
    __weak typeof(self) weakSelf = self;
    dispatch_once_on_main_thread(&onceToken, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id __nullable userAgent, NSError * __nullable error) {
            strongSelf.userAgent = userAgent;
            strongSelf.webView = nil;
            if (![NSKeyedArchiver archiveRootObject:strongSelf.userAgent toFile:[strongSelf userAgentFilePath]])
            {
                DLog(@"Visilabs: WARNING - Unable to archive userAgent!!!");
            }
        }];
    });
}


//TODO shownNotifications keyedarchive'lenecek

/*Notification Methods*/

#pragma mark - Notification


- (void)trackNotificationClick:(VisilabsNotification *)notification
{
    if(notification == nil || notification.ID < 1)
    {
        DLog(@"Visilabs: WARNING - Tried to record empty or nil notification. Ignoring.");
        return;
    }
    
    
    
    
    int actualTimeOfevent = (int)[[NSDate date] timeIntervalSince1970];
    
    
    NSString *segURL = [NSString stringWithFormat:@"%@/%@/%@?%@=%@&%@=%@&%@=%@&%@=%@&%@=%i&%@=%@&%@=%@&%@=%@", self.segmentURL,self.dataSource,@"om.gif"
                        ,@"OM.cookieID", self.cookieID
                        ,@"OM.vchannel", self.channel
                        ,@"OM.siteID",self.siteID
                        ,@"OM.oid",self.organizationID
                        ,@"dat", actualTimeOfevent
                        ,@"OM.uri",[self urlEncode:@"/OM_evt.gif"]
                        ,@"OM.domain",[NSString stringWithFormat:@"%@_%@", self.dataSource, @"IOS"]
                        ,[VisilabsConfig APIVER_KEY], @"IOS"];
    
    if(self.exVisitorID != nil &&  ![self.exVisitorID isEqual: @""])
    {
        NSString *escapedIdentity = [self urlEncode:self.exVisitorID];
        segURL = [NSString stringWithFormat:@"%@%@=%@",segURL,@"OM.exVisitorID",escapedIdentity];
    }
    
    if(notification.queryString && notification.queryString.length > 0){
        segURL = [NSString stringWithFormat:@"%@&%@",segURL,notification.queryString];
    }
    

    
    
    NSString *rtURL = nil;
    if(self.realTimeURL != nil && ![self.realTimeURL isEqualToString:@""] )
    {
        rtURL = [segURL stringByReplacingOccurrencesOfString:self.segmentURL withString:self.realTimeURL];
    }
    DLog(@"%@ tracking notification click %@", self, segURL);
    
    @synchronized(self)
    {
        [self.sendQueue addObject:segURL];
        if(rtURL != nil)
        {
            [self.sendQueue addObject:rtURL];
        }
    }
    [self send];
}


- (void)checkForNotificationsResponseWithCompletion:(void (^)(NSArray *notifications))completion pageName:(NSString *)pageName properties:(NSMutableDictionary *)properties
{
    
    self.notificationResponseCached = NO;
    
    dispatch_async(self.serialQueue, ^{
        
        NSMutableArray *parsedNotifications = [NSMutableArray array];
        
        if (!self.notificationResponseCached) {
            
            if(pageName == nil){
                return;
            }
            
            int actualTimeOfevent = (int)[[NSDate date] timeIntervalSince1970];
            NSString *actURL = [NSString stringWithFormat:@"%@?%@=%@&%@=%@&%@=%@&%@=%i&%@=%@&%@=%@", self.actionURL
                                ,@"OM.cookieID", self.cookieID
                                ,@"OM.siteID",self.siteID
                                ,@"OM.oid",self.organizationID
                                ,@"dat", actualTimeOfevent
                                ,[VisilabsConfig APIVER_KEY], @"IOS"
                                ,@"OM.uri", [self urlEncode:pageName]];
            
            if(self.exVisitorID != nil &&  ![self.exVisitorID isEqual: @""])
            {
                NSString *escapedIdentity = [self urlEncode:self.exVisitorID];
                actURL = [NSString stringWithFormat:@"%@&%@=%@",actURL,@"OM.exVisitorID",escapedIdentity];
            }
            
            if(self.visitData != nil &&  ![self.visitData isEqual: @""])
            {
                NSString *escapedVisitData = [self urlEncode:self.visitData];
                actURL = [NSString stringWithFormat:@"%@&%@=%@",actURL,@"OM.vcap",escapedVisitData];
            }
            
            if(self.visitorData != nil &&  ![self.visitorData isEqual: @""])
            {
                NSString *escapedVisitorData = [self urlEncode:self.visitorData];
                actURL = [NSString stringWithFormat:@"%@&%@=%@",actURL,@"OM.viscap",escapedVisitorData];
            }
            
            if(self.tokenID != nil &&  ![self.tokenID isEqual: @""])
            {
                NSString *escapedToken = [self urlEncode:self.tokenID];
                actURL = [NSString stringWithFormat:@"%@&%@=%@",actURL,@"OM.sys.TokenID",escapedToken];
            }
            if(self.appID != nil &&  ![self.appID isEqual: @""])
            {
                NSString *escapedAppID = [self urlEncode:self.appID];
                actURL = [NSString stringWithFormat:@"%@&%@=%@",actURL,@"OM.sys.AppID",escapedAppID];
            }
            
            
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
                        actURL = [[actURL stringByAppendingString:parameter] mutableCopy];
                    }
                    
                    if (properties && [properties objectForKey:key]) {
                        [properties removeObjectForKey:key];
                    }
                    
                }
            }
            
            if(properties){
                for (NSString *key in [properties allKeys])
                {
                    if ([key  isEqual: @"OM.cookieID"] || [key  isEqual: @"OM.siteID"] || [key  isEqual: @"OM.oid"] || [key  isEqual: [VisilabsConfig APIVER_KEY]]
                        || [key  isEqual: @"OM.uri"] || [key  isEqual: @"OM.exVisitorID"]) {
                        continue;
                    }
                    
                    
                    NSString *value = [properties objectForKey:key];
                    if (value && [value length] > 0)
                    {
                        NSString* encodedValue = [[Visilabs callAPI] urlEncode:value];
                        NSString *parameter = [NSString stringWithFormat:@"&%@=%@", key, encodedValue];
                        actURL = [[actURL stringByAppendingString:parameter] mutableCopy];
                    }
                }
            }
            
            
            
            NSURL *URL = [NSURL URLWithString:actURL];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
            [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
            NSError *error = nil;
            NSURLResponse *urlResponse = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
            if (error) {
                DLog(@"%@ notification check http error: %@", self, error);
                return;
            }
            
            NSArray *rawNotifications = (NSArray *)[NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&error];
            if (error) {
                DLog(@"%@ notification check json error: %@, data: %@", self, error, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                return;
            }
            
            if (rawNotifications && [rawNotifications isKindOfClass:[NSArray class]]) {
                for (id obj in rawNotifications) {
                    VisilabsNotification *notification = [VisilabsNotification notificationWithJSONObject:obj];
                    if (notification) {
                        [parsedNotifications addObject:notification];
                    }
                }
            } else {
                DLog(@"%@ in-app notifs check response format error: %@", self, rawNotifications);
            }
            
            //self.notifications = [NSArray arrayWithArray:parsedNotifications];
            self.notificationResponseCached = YES;
        }else {
            DLog(@"%@ notification cache found, skipping network request", self);
        }
        
        
        
        if (completion) {
            completion(parsedNotifications);
        }
        
    });
}

+ (UIViewController *)topPresentedViewController
{
    UIViewController *controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    return controller;
}

+ (BOOL)canPresentFromViewController:(UIViewController *)viewController
{
    // This fixes the NSInternalInconsistencyException caused when we try present a
    // survey on a viewcontroller that is itself being presented.
    if ([viewController isBeingPresented] || [viewController isBeingDismissed]) {
        return NO;
    }
    
    Class UIAlertControllerClass = NSClassFromString(@"UIAlertController");
    if (UIAlertControllerClass && [viewController isKindOfClass:UIAlertControllerClass]) {
        return NO;
    }
    
    return YES;
}


//TODO: bunlara shown kontrolü koyulacak.showNotificationWithID,showNotificationWithType,showNotification

- (void)showNotification:(NSString *)pageName
{
    [self checkForNotificationsResponseWithCompletion:^(NSArray *notifications) {
        if ([notifications count] > 0) {
            [self showNotificationWithObject:notifications[0]];
        }
    } pageName:pageName properties:nil];
}

- (void)showNotification:(NSString *)pageName properties:(NSDictionary *)properties
{
    [self checkForNotificationsResponseWithCompletion:^(NSArray *notifications) {
        if ([notifications count] > 0) {
            [self showNotificationWithObject:notifications[0]];
        }
    } pageName:pageName properties:[properties mutableCopy]];
}


- (void)showNotificationWithObject:(VisilabsNotification *)notification
{
    NSData *image = notification.image;
    
    if (!image) {
        //NSMutableArray *notifications = [NSMutableArray arrayWithArray:_notifications];
        //[notifications removeObject:notification];
        //self.notifications = [NSArray arrayWithArray:notifications];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentlyShowingNotification) {
            DLog(@"%@ already showing in-app notification: %@", self, self.currentlyShowingNotification);
        }else {
            self.currentlyShowingNotification = notification;
            BOOL shown;
            
            if (notification.visitData != nil && ![notification.visitData  isEqual: @""]) {
                self.visitData = notification.visitData;
            }
            if (notification.visitorData != nil && ![notification.visitorData  isEqual: @""]) {
                self.visitorData = notification.visitorData;
            }
            
            
            if ([notification.type isEqualToString:VisilabsNotificationTypeMini]) {
                shown = [self showMiniNotificationWithObject:notification];
            } else {
                shown = [self showFullNotificationWithObject:notification];
            }
            
            /*
             if (shown && ![notification.title isEqualToString:@"$ignore"]) {
             [self markNotificationShown:notification];
             }
             */
            
            if (!shown) {
                self.currentlyShowingNotification = nil;
            }
        }
    });
}

- (BOOL)showMiniNotificationWithObject:(VisilabsNotification *)notification
{
    VisilabsMiniNotificationViewController *controller = [[VisilabsMiniNotificationViewController alloc] init];
    controller.notification = notification;
    controller.delegate = self;
    controller.backgroundColor = self.miniNotificationBackgroundColor;
    self.notificationViewController = controller;
    
    [controller showWithAnimation];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.miniNotificationPresentationTime * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self notificationController:controller wasDismissedWithStatus:NO];
    });
    return YES;
}

- (BOOL)showFullNotificationWithObject:(VisilabsNotification *)notification
{
    UIViewController *presentingViewController = [Visilabs topPresentedViewController];
    
    if ([[self class] canPresentFromViewController:presentingViewController]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"VisilabsNotification" bundle:[NSBundle bundleForClass:Visilabs.class]];
        VisilabsFullNotificationViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"VisilabsFullNotificationViewController"];
        
        controller.backgroundImage = [presentingViewController.view visilabs_snapshotImage];
        controller.notification = notification;
        controller.delegate = self;
        self.notificationViewController = controller;
        
        [presentingViewController presentViewController:controller animated:YES completion:nil];
        return YES;
    } else {
        return NO;
    }
}

/*
 - (void)markNotificationShown:(VisilabsNotification *)notification
 {
 DLog(@"%@ marking notification shown: %@, %@", self, @(notification.ID), _shownNotifications);
 
 [_shownNotifications addObject:@(notification.ID)];
 
 //TODO: gösterilen notification'ı track edecek miyiz?
 //[self trackNotification:notification event:@"$campaign_delivery"];
 }
 */

- (void)notificationController:(VisilabsNotificationViewController *)controller wasDismissedWithStatus:(BOOL)status
{
    if (controller == nil || self.currentlyShowingNotification != controller.notification) {
        return;
    }
    
    void (^completionBlock)(void)  = ^void(){
        self.currentlyShowingNotification = nil;
        self.notificationViewController = nil;
    };
    
    if (status && controller.notification.buttonURL) {
        DLog(@"%@ opening URL %@", self, controller.notification.buttonURL);
        BOOL success = [[UIApplication sharedApplication] openURL:controller.notification.buttonURL];
        
        [controller hideWithAnimation:!success completion:completionBlock];
        
        if (!success) {
            DLog(@"Visilabs failed to open given URL: %@", controller.notification.buttonURL);
        }
        
        //TODO: Notification butonuna tıkladığında track etmek için
        [self trackNotificationClick:controller.notification];
    } else {
        [controller hideWithAnimation:YES completion:completionBlock];
    }
}

//TODO: bunlara bak
- (void)applicationWillTerminate:(NSNotification*) notification
{
    DLog(@"%@ will terminate", self);
    dispatch_async(_serialQueue, ^{
        [self archive];
    });
    
    @synchronized(self)
    {
        if(self.timer != nil)
        {
            [self.timer invalidate];
            self.timer = nil;
        }
        
        if(self.segmentConnection != nil)
        {
            [self.segmentConnection cancel];
        }
    }
}

- (void)applicationWillEnterForeground:(NSNotificationCenter*) notification
{
    @synchronized(self)
    {
        if(self.organizationID != nil && self.siteID != nil && self.segmentURL && self.dataSource)
        {
            if (!self.sendQueue)
            {
                self.sendQueue = [NSMutableArray array];
            }
        }
    }
}


- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    DLog(@"%@ application did become active", self);
    
    self.loggerCookieKey = nil;
    self.loggerCookieValue = nil;
    self.realTimeCookieKey = nil;
    self.realTimeCookieValue = nil;
    
    /*
     if (self.checkForNotificationsOnLoggerRequest) {
     [self checkForNotificationsResponseWithCompletion:^(NSArray *notifications) {
     if (self.showNotificationOnActive && notifications && [notifications count] > 0) {
     [self showNotificationWithObject:notifications[0]];
     }
     }];
     }
     */
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    DLog(@"%@ did enter background", self);
     dispatch_async(_serialQueue, ^{
     [self archive];
     //self.notificationResponseCached = NO;
     });
     
}


#pragma mark - Persistence

- (NSString *)filePathForData:(NSString *)data
{
    NSString *filename = [NSString stringWithFormat:@"%@", data];
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
}

- (NSString *)cookieIDFilePath
{
    return [self filePathForData:self.cookieIDArchiveKey];
}

- (NSString *)exVisitorIDFilePath
{
    return [self filePathForData:self.exVisitorIDArchiveKey];
}

- (NSString *)tokenIDFilePath
{
    return [self filePathForData:self.tokenIDArchiveKey];
}

- (NSString *)appIDFilePath
{
    return [self filePathForData:self.appIDArchiveKey];
}

- (NSString *)userAgentFilePath
{
    return [self filePathForData:self.userAgentArchiveKey];
}

- (NSString *)propertiesFilePath
{
    return [self filePathForData:self.propertiesArchiveKey];
}

-(void)archive
{
    [self archiveProperties];
}

- (void)archiveProperties
{
    
     NSString *filePath = [self propertiesFilePath];
     NSMutableDictionary *dic = [NSMutableDictionary dictionary];
     //[dic setValue:self.shownNotifications forKey:@"shownNotifications"];
     [dic setValue:self.visitorData forKey:@"visitorData"];
     if (![NSKeyedArchiver archiveRootObject:dic toFile:filePath]) {
         DLog(@"%@ unable to archive properties data", self);
     }
    
}

- (void)unarchive
{
    [self unarchiveProperties];
}

- (id)unarchiveFromFile:(NSString *)filePath
{
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        DLog(@"%@ unarchived data from %@: %@", self, filePath, unarchivedData);
    }
    @catch (NSException *exception) {
        DLog(@"%@ unable to unarchive data in %@, starting fresh", self, filePath);
        unarchivedData = nil;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!removed) {
            DLog(@"%@ unable to remove archived file at %@ - %@", self, filePath, error);
        }
    }
    return unarchivedData;
}

- (void)unarchiveProperties
{
    
     NSDictionary *dic = (NSDictionary *)[self unarchiveFromFile:[self propertiesFilePath]];
     if (dic) {
     //self.shownNotifications = dic[@"shownNotifications"] ? dic[@"shownNotifications"] : [NSMutableSet set];
     self.visitorData = dic[@"visitorData"] ? dic[@"visitorData"] : @"";
     }
    
}

- (NSString *)getIDFA
{
    if([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled])
    {
        NSUUID *IDFA = [[ASIdentifierManager sharedManager] advertisingIdentifier];
        return [IDFA UUIDString];
    }
    
    return @"";
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Visilabs: %p %@>", self, self.siteID];
}








-(NSString*) exVisitorID
{
    return _exVisitorID;
}

-(NSString*) cookieID
{
    return _cookieID;
}

-(NSString*) organizationID
{
    return _organizationID;
}

-(NSString*) siteID
{
    return _siteID;
}

-(void)registerForNetworkReachabilityNotifications {
    if (!reachability) {
        reachability = [VisilabsReachability reachabilityForInternetConnection];
        if ([reachability currentReachabilityStatus] == ReachableViaWiFi ||
            [reachability currentReachabilityStatus] == ReachableViaWWAN) {
            _isOnline = YES;
        } else {
            _isOnline = NO;
        }
        [reachability startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkReachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil];
    }
}

- (void)networkReachabilityChanged:(NSNotification *)note {
    if ([reachability currentReachabilityStatus] == ReachableViaWiFi ||
        [reachability currentReachabilityStatus] == ReachableViaWWAN) {
        _isOnline = YES;
    } else {
        _isOnline = NO;
    }
    DLog(@"Visilabs network status changed. Current status: %d", _isOnline);
}

- (VisilabsTargetRequest *)buildActionRequest:(VisilabsTargetRequestType)actionType{
    return [self buildActionRequest:actionType withActionID:nil];
}

- (VisilabsTargetRequest *)buildActionRequest:(VisilabsTargetRequestType)actionType withActionID:(NSString *)actionID{
    VisilabsTargetRequest *request = (VisilabsTargetRequest *)[self buildAction];
    request.targetRequestType = actionType;
    request.actionID = actionID;
    request.path = nil;
    request.headers = nil;
    request.method = @"GET";
    request.requestMethod = @"GET";
    [request setArgs:nil];
    return request;
}

- (VisilabsTargetRequest *)buildTargetRequest:(NSString *)zoneID withProductCode:(NSString *)productCode{
    VisilabsTargetRequest *request = (VisilabsTargetRequest *)[self buildAction];
    request.targetRequestType = VisilabsTargetRequestTypeRecommendation;
    request.zoneID = zoneID;
    request.productCode = productCode;
    request.path = nil;
    request.headers = nil;
    request.method = @"GET";
    request.requestMethod = @"GET";
    [request setArgs:nil];
    return request;
}

- (VisilabsTargetRequest *)buildTargetRequest:(NSString *)zoneID withProductCode:(NSString *)productCode withProperties:(NSMutableDictionary *)properties withFilters:(NSMutableArray<VisilabsTargetFilter *> *) filters{
    VisilabsTargetRequest *request = (VisilabsTargetRequest *)[self buildAction];
    request.targetRequestType = VisilabsTargetRequestTypeRecommendation;
    request.zoneID = zoneID;
    request.productCode = productCode;
    request.path = nil;
    request.headers = nil;
    request.method = @"GET";
    request.requestMethod = @"GET";
    request.properties = properties;
    request.filters = filters;
    [request setArgs:nil];
    return request;
}


- (VisilabsGeofenceRequest *)buildGeofenceRequest:(NSString *)action withActionID:(NSString *)actionID withLatitude:(double)latitude withLongitude:(double)longitude withGeofenceID:(NSString *)geofenceID withIsDwell:(BOOL) isDwell withIsEnter:(BOOL) isEnter {
    VisilabsGeofenceRequest *request = (VisilabsGeofenceRequest *)[self buildGeofenceAction];
    request.action = action;
    request.actionID = actionID;
    request.path = nil;
    request.headers = nil;
    request.method = @"GET";
    request.requestMethod = @"GET";
    request.lastKnownLatitude = latitude;
    request.lastKnownLongitude = longitude;
    request.geofenceID = geofenceID;
    request.isDwell = isDwell;
    request.isEnter = isEnter;
    [request setArgs:nil];
    
    return request;
}

- (VisilabsAction*)buildAction{
    if (API == nil) {
        @throw([NSException exceptionWithName:@"Visilabs Not Ready"
                                       reason:@"Visilabs failed to initialize"
                                     userInfo:@{}]);
    }
    VisilabsAction *action = nil;
    action = [[VisilabsTargetRequest alloc] init];
    return action;
}

- (VisilabsAction*)buildGeofenceAction{
    if (API == nil) {
        @throw([NSException exceptionWithName:@"Visilabs Not Ready"
                                       reason:@"Visilabs failed to initialize"
                                     userInfo:@{}]);
    }
    VisilabsAction *action = nil;
    action = [[VisilabsGeofenceRequest alloc] init];
    return action;
}


+ (Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withRESTURL:(NSString *)RESTURL withEncryptedDataSource:(NSString *)encryptedDataSource
{
    @synchronized(self)
    {
        if (API == nil) {
            API = [[Visilabs alloc] init];
            [API initAPI:organizationID withSiteID:siteID withSegmentURL:segmentURL withDataSource:dataSource withRealTimeURL:realTimeURL withChannel:channel withRequestTimeout:seconds  withRESTURL:RESTURL withEncryptedDataSource:encryptedDataSource withTargetURL:nil  withActionURL:nil withGeofenceURL: nil withGeofenceEnabled:NO withMaxGeofenceCount : 20];
        }
    }
    return API;
}

+ (Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds
{
    @synchronized(self)
    {
        if (API == nil) {
            API = [[Visilabs alloc] init];
            [API initAPI:organizationID withSiteID:siteID withSegmentURL:segmentURL withDataSource:dataSource withRealTimeURL:realTimeURL withChannel:channel withRequestTimeout:seconds withRESTURL:nil withEncryptedDataSource:nil withTargetURL:nil withActionURL:nil withGeofenceURL: nil withGeofenceEnabled:NO withMaxGeofenceCount : 20];
        }
    }
    return API;
}

+ (Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel
{
    @synchronized(self)
    {
        if (API == nil) {
            API = [[Visilabs alloc] init];
            [API initAPI:organizationID withSiteID:siteID withSegmentURL:segmentURL withDataSource:dataSource withRealTimeURL:realTimeURL withChannel:channel withRequestTimeout:60 withRESTURL:nil withEncryptedDataSource:nil withTargetURL:nil withActionURL:nil withGeofenceURL: nil withGeofenceEnabled:NO withMaxGeofenceCount : 20];
        }
    }
    return API;
}

+ (Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withTargetURL:(NSString *)targetURL
{
    @synchronized(self)
    {
        if (API == nil) {
            API = [[Visilabs alloc] init];
            [API initAPI:organizationID withSiteID:siteID withSegmentURL:segmentURL withDataSource:dataSource withRealTimeURL:realTimeURL withChannel:channel withRequestTimeout:seconds withRESTURL:nil withEncryptedDataSource:nil withTargetURL:targetURL withActionURL:nil withGeofenceURL: nil withGeofenceEnabled:NO withMaxGeofenceCount : 20];
        }
    }
    return API;
}

+ (Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withTargetURL:(NSString *)targetURL withActionURL:(NSString *)actionURL
{
    @synchronized(self)
    {
        if (API == nil) {
            API = [[Visilabs alloc] init];
            [API initAPI:organizationID withSiteID:siteID withSegmentURL:segmentURL withDataSource:dataSource withRealTimeURL:realTimeURL withChannel:channel withRequestTimeout:seconds withRESTURL:nil withEncryptedDataSource:nil withTargetURL:targetURL withActionURL:actionURL withGeofenceURL: nil withGeofenceEnabled:NO withMaxGeofenceCount : 20];
        }
    }
    return API;
}

+ (Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withTargetURL:(NSString *)targetURL withActionURL:(NSString *)actionURL  withGeofenceURL:(NSString *)geofenceURL withGeofenceEnabled:(BOOL) geofenceEnabled
{
    @synchronized(self)
    {
        if (API == nil) {
            API = [[Visilabs alloc] init];
            [API initAPI:organizationID withSiteID:siteID withSegmentURL:segmentURL withDataSource:dataSource withRealTimeURL:realTimeURL withChannel:channel withRequestTimeout:seconds withRESTURL:nil withEncryptedDataSource:nil withTargetURL:targetURL withActionURL:actionURL  withGeofenceURL: geofenceURL withGeofenceEnabled:geofenceEnabled withMaxGeofenceCount : 20];
        }
    }
    return API;
}

+ (Visilabs *) createAPI : (NSString *) organizationID  withSiteID: (NSString *) siteID withSegmentURL: (NSString *) segmentURL withDataSource :(NSString *) dataSource withRealTimeURL:(NSString *)realTimeURL withChannel:(NSString *)channel withRequestTimeout:(NSInteger)seconds withTargetURL:(NSString *)targetURL withActionURL:(NSString *)actionURL  withGeofenceURL:(NSString *)geofenceURL withGeofenceEnabled:(BOOL) geofenceEnabled withMaxGeofenceCount:(NSInteger)maxGeofenceCount
{
    @synchronized(self)
    {
        if (API == nil) {
            API = [[Visilabs alloc] init];
            [API initAPI:organizationID withSiteID:siteID withSegmentURL:segmentURL withDataSource:dataSource withRealTimeURL:realTimeURL withChannel:channel withRequestTimeout:seconds withRESTURL:nil withEncryptedDataSource:nil withTargetURL:targetURL withActionURL:actionURL  withGeofenceURL: geofenceURL withGeofenceEnabled:geofenceEnabled
   withMaxGeofenceCount : maxGeofenceCount];
        }
    }
    return API;
    
}

+ (Visilabs *) callAPI
{
    @synchronized(self)
    {
        if (API == nil)
        {
            DLog(@"Visilabs: WARNING - Visilabs object is not created yet.");
        }
    }
    return API;
}







- (void) initAPI:(NSString *)oID withSiteID:(NSString*) sID withSegmentURL:(NSString *) sURL withDataSource:(NSString *) dSource withRealTimeURL:(NSString *)rURL withChannel:(NSString *)chan withRequestTimeout:(NSInteger)seconds  withRESTURL:(NSString *)restURL withEncryptedDataSource:(NSString *) eDataSource withTargetURL:(NSString *)tURL withActionURL:(NSString *)aURL withGeofenceURL:(NSString *)gURL withGeofenceEnabled:(BOOL) gEnabled  withMaxGeofenceCount:(NSInteger)maxGeofenceCount
{
    
    [self registerForNetworkReachabilityNotifications];
    
    self.checkForNotificationsOnLoggerRequest = YES;
    self.miniNotificationPresentationTime = 10.0;
    self.miniNotificationBackgroundColor = nil;
    NSString *label = [NSString stringWithFormat:@"visilabs.%@.%p", self.siteID, self];
    self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    self.actionURL = aURL;
    self.notificationResponseCached = NO;
    
    self.maxGeofenceCount = 20;
    if(maxGeofenceCount < 20 && maxGeofenceCount >0)
    {
        self.maxGeofenceCount = maxGeofenceCount;
    }
    
    self.requestTimeout = seconds;
    self.organizationID = oID;
    self.siteID =sID;
    self.segmentURL =sURL;
    self.dataSource = dSource;
    self.realTimeURL = rURL;
    self.channel = [self urlEncode:chan];
    self.RESTURL = restURL;
    self.encryptedDataSource = eDataSource;
    
    self.geofenceURL = gURL;
    self.geofenceEnabled = gEnabled;
    
    
    self.targetURL = tURL;
    self.mobileEndPoint = [[VisilabsConfig MOBILEENDPOINT] mutableCopy];
    
    
    if(self.channel == nil)
    {
        self.channel = @"IOS";
    }
    self.cookieIDArchiveKey = @"Visilabs.identity";
    self.exVisitorIDArchiveKey = @"Visilabs.exVisitorID";
    self.propertiesArchiveKey = @"Visilabs.properties";
    
    self.tokenIDArchiveKey = @"Visilabs.tokenID";
    self.appIDArchiveKey = @"Visilabs.appID";
    self.userAgentArchiveKey = @"Visilabs.userAgent";
    
    @try {
        self.identifierForAdvertising = [self getIDFA];
    }@catch(NSException *exception) {
        DLog(@"Visilabs: Identifier for advertising can not be retrieved.");
    }
    
    
    @try {
        self.cookieID = [NSKeyedUnarchiver unarchiveObjectWithFile:[self cookieIDFilePath]];
    }@catch(NSException *exception) {
        DLog(@"Visilabs: Error while unarchiving cookieID.");
    }
    if(!self.cookieID)
    {
        [self setCookieID];
    }
    
    
    @try {
        self.exVisitorID = [NSKeyedUnarchiver unarchiveObjectWithFile:[self exVisitorIDFilePath]];
    }@catch(NSException *exception) {
        DLog(@"Visilabs: Error while unarchiving exVisitorID.");
    }
    
    
    if(!self.exVisitorID)
    {
        [self clearExVisitorID];
    }
    
    
    @try {
        self.tokenID = [NSKeyedUnarchiver unarchiveObjectWithFile:[self tokenIDFilePath]];
    }@catch(NSException *exception) {
        DLog(@"Visilabs: Error while unarchiving tokenID.");
    }
    
    @try {
        self.appID = [NSKeyedUnarchiver unarchiveObjectWithFile:[self appIDFilePath]];
    }@catch(NSException *exception) {
        DLog(@"Visilabs: Error while unarchiving appID.");
    }

    self.userAgent = @"IOS";
    @try {
        self.userAgent = [NSKeyedUnarchiver unarchiveObjectWithFile:[self userAgentFilePath]];
    }@catch(NSException *exception) {
        DLog(@"Visilabs: Error while unarchiving userAgent.");
    }
    
    [self computeWebViewUserAgent];
    
    
    
    
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    
    
    [self unarchive];
    
    //TODO: buna bak niye çağırıyoruz?
    [self applicationWillEnterForeground:nil];
    
    if(self.geofenceEnabled && self.geofenceURL != nil){
        [VisilabsGeofenceApp sharedInstance].isLocationServiceEnabled = YES;
        //[[VisilabsGeofenceManager sharedInstance] start];
    }
    
}


- (void) send
{
    @synchronized(self)
    {
        if(self.timer != nil)
        {
            [self.timer invalidate];
            self.timer = nil;
        }
        
        if(self.segmentConnection != nil)
        {
            return;
        }
        
        NSString *nextAPICall = nil;
        
        if([self.sendQueue count] == 0)
        {
            return;
        }
        
        nextAPICall = [self.sendQueue objectAtIndex:0];
        
        NSString *referer = nil;
        if([nextAPICall rangeOfString:@"OM.uri="].location == NSNotFound)
        {
            referer = @"";
        }
        else
        {
            referer = [nextAPICall stringBetweenString:@"OM.uri=" andString:@"&"];
        }
        
        NSURL *url = [NSURL URLWithString:nextAPICall];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
        [request setValue:referer forHTTPHeaderField:@"Referer"];
        
        if([nextAPICall containsString:[VisilabsConfig LOGGER_URL] options:NSCaseInsensitiveSearch]
           && self.loggerCookieKey != nil && ![self.loggerCookieKey  isEqual: @""]
           && self.loggerCookieValue != nil && ![self.loggerCookieValue  isEqual: @""])
        {
            NSString *cookieString = self.loggerCookieKey ;
            cookieString = [cookieString stringByAppendingString:@"="];
            cookieString = [cookieString stringByAppendingString:self.loggerCookieValue];
            
            if (self.loggerOM3rdCookieValue != nil && ![self.loggerOM3rdCookieValue isEqual: @""]) {
                cookieString = [cookieString stringByAppendingString:@";"];
                cookieString = [cookieString stringByAppendingString:[VisilabsConfig OM_3_KEY]];
                cookieString = [cookieString stringByAppendingString:@"="];
                cookieString = [cookieString stringByAppendingString:self.loggerOM3rdCookieValue];
            }
            
            [request setValue:cookieString forHTTPHeaderField:@"Cookie"];
        }
        else if ([nextAPICall containsString:[VisilabsConfig REAL_TIME_URL] options:NSCaseInsensitiveSearch]
            && self.realTimeCookieKey != nil && ![self.realTimeCookieKey isEqual: @""]
            && self.realTimeCookieValue != nil && ![self.realTimeCookieValue  isEqual: @""])
        {
            NSString *cookieString = self.realTimeCookieKey ;
            cookieString = [cookieString stringByAppendingString:@"="];
            cookieString = [cookieString stringByAppendingString:self.realTimeCookieValue];
            
            if (self.realTimeOM3rdCookieValue != nil && ![self.realTimeOM3rdCookieValue isEqual: @""]) {
                cookieString = [cookieString stringByAppendingString:@";"];
                cookieString = [cookieString stringByAppendingString:[VisilabsConfig OM_3_KEY]];
                cookieString = [cookieString stringByAppendingString:@"="];
                cookieString = [cookieString stringByAppendingString:self.realTimeOM3rdCookieValue];
            }
            
            [request setValue:cookieString forHTTPHeaderField:@"Cookie"];
        }
        
            
        if(self.requestTimeout != 0){
            [request setTimeoutInterval:self.requestTimeout];
        }
        
        self.segmentConnection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        
        [self.segmentConnection start];
        
        if(![NSThread isMainThread]){
            while(self.segmentConnection) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        }
        
    }
    
}

- (NSString *)urlizeProps:(NSDictionary *)props
{
    NSMutableString *propsURLPart = [NSMutableString string];
    
    for(id propKey in [props allKeys])
    {
        if (![propKey isKindOfClass:[NSString class]])
        {
            DLog(@"Visilabs: WARNING - property keys must be NSString. Dropping property.");
            continue;
        }
        NSString *stringKey = (NSString *)propKey;
        
        
        if([stringKey length] == 0)
        {
            DLog(@"Visilabs: WARNING - property keys must not be empty strings. Dropping property.");
            continue;
        }
        
        NSString *stringValue = nil;
        if([props objectForKey:stringKey] == nil)
        {
            DLog(@"Visilabs: WARNING - property value cannot be nil. Dropping property.");
            continue;
        }
        else if([[props objectForKey:stringKey] isKindOfClass:[NSNumber class]])
        {
            NSNumber *numberValue = (NSNumber *)[props objectForKey:stringKey];
            stringValue = [numberValue stringValue];
        }
        else if([[props objectForKey:stringKey] isKindOfClass:[NSString class]])
        {
            stringValue = (NSString *)[props objectForKey:stringKey];
        }
        
        if(stringValue == nil)
        {
            DLog(@"Visilabs: WARNING - property value cannot be of type %@. Dropping property.", [[[props objectForKey:stringKey] class] description]);
            continue;
        }
        
        if([stringValue length] == 0)
        {
            DLog(@"Visilabs: WARNING - property values must not be empty strings. Dropping property.");
            continue;
        }
        
        
        NSString *escapedKey = [self urlEncode:stringKey];
        if([escapedKey length] > 255)
        {
            DLog(@"Visilabs: WARNING - property key cannot longer than 255 characters. When URL escaped, your key is %lu characters long (the submitted value is %@, the URL escaped value is %@). Dropping property.", (unsigned long)[escapedKey length], stringKey, escapedKey);
            continue;
        }
        
        NSString *escapedValue = [self urlEncode:stringValue];
        [propsURLPart appendFormat:@"&%@=%@", escapedKey, escapedValue];
    }
    
    return propsURLPart;
}

- (NSString *)urlEncode:(NSString *)prior
{
    NSString * after = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes( NULL,(CFStringRef)prior, NULL,(CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 ));
    return after;
}

- (void)sendCampaignParameters:(NSMutableDictionary *)properties
{
    if ([[properties allKeys] containsObject:@"OM.cookieID"])
    {
        NSString *cookieid = [properties objectForKey: @"OM.cookieID"];
        
        if(![self.cookieID isEqualToString:cookieid]){
            [VisilabsPersistentTargetManager clearParameters];
        }
        
        self.cookieID = cookieid;
        if (![NSKeyedArchiver archiveRootObject:self.cookieID toFile:[self cookieIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive identity!!!");
        }
        [properties removeObjectForKey:@"OM.cookieID"];
    }
    
    if ([[properties allKeys] containsObject:@"OM.exVisitorID"])
    {
        NSString     *exvisitorid = [properties objectForKey: @"OM.exVisitorID"];
        
        if(![self.exVisitorID isEqualToString:exvisitorid]){
            [VisilabsPersistentTargetManager clearParameters];
        }
        
        if([self exVisitorID] != nil &&  ![[self exVisitorID] isEqualToString:exvisitorid])
        {
            [self setCookieID];
        }
        
        
        self.exVisitorID = exvisitorid;
        if (![NSKeyedArchiver archiveRootObject:self.exVisitorID toFile:[self exVisitorIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive new identity!!!");
        }
        [properties removeObjectForKey:@"OM.exVisitorID"];
    }
    
    if ([[properties allKeys] containsObject:@"OM.sys.TokenID"])
    {
        NSString *tokenid = [properties objectForKey: @"OM.sys.TokenID"];
        self.tokenID = tokenid;
        
        if (![NSKeyedArchiver archiveRootObject:self.tokenID toFile:[self tokenIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive tokenID!!!");
        }
        [properties removeObjectForKey:@"OM.sys.TokenID"];
    }
    
    if ([[properties allKeys] containsObject:@"OM.sys.AppID"])
    {
        NSString *appid = [properties objectForKey: @"OM.sys.AppID"];
        self.appID = appid;
        
        if (![NSKeyedArchiver archiveRootObject:self.appID toFile:[self appIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive appID!!!");
        }
        [properties removeObjectForKey:@"OM.sys.AppID"];
    }
    
    
    if ([[properties allKeys] containsObject:@"OM.m_adid"])
    {
        [properties removeObjectForKey:@"OM.m_adid"];
    }
    
    if ([[properties allKeys] containsObject:[VisilabsConfig APIVER_KEY]])
    {
        [properties removeObjectForKey:[VisilabsConfig APIVER_KEY]];
    }
    
    
    NSString *chan = self.channel;
    if ([[properties allKeys] containsObject:@"OM.vchannel"])
    {
        chan = [self urlEncode:[properties objectForKey: @"OM.vchannel"]];
        [properties removeObjectForKey:@"OM.vchannel"];
    }

    int actualTimeOfevent = (int)[[NSDate date] timeIntervalSince1970];
    
    NSString *segURL = [NSString stringWithFormat:@"%@/%@/%@?%@=%@&%@=%@&%@=%@&%@=%@&%@=%i&%@=%@&%@=%@&%@=%@&", self.segmentURL,self.dataSource,@"om.gif"
                        ,@"OM.cookieID", self.cookieID
                        ,@"OM.vchannel", chan
                        ,@"OM.siteID",self.siteID
                        ,@"OM.oid",self.organizationID
                        ,@"dat", actualTimeOfevent
                        ,@"OM.mappl",@"true"
                        ,@"OM.m_adid",self.identifierForAdvertising
                        ,[VisilabsConfig APIVER_KEY], @"IOS"];
    
    if(self.exVisitorID != nil &&  ![self.exVisitorID isEqual: @""])
    {
        NSString *escapedIdentity = [self urlEncode:self.exVisitorID];
        segURL = [NSString stringWithFormat:@"%@%@=%@",segURL,@"OM.exVisitorID",escapedIdentity];
    }
    
    if(self.tokenID != nil &&  ![self.tokenID isEqual: @""])
    {
        NSString *escapedToken = [self urlEncode:self.tokenID];
        segURL = [NSString stringWithFormat:@"%@&%@=%@",segURL,@"OM.sys.TokenID",escapedToken];
    }
    if(self.appID != nil &&  ![self.appID isEqual: @""])
    {
        NSString *escapedAppID = [self urlEncode:self.appID];
        segURL = [NSString stringWithFormat:@"%@&%@=%@",segURL,@"OM.sys.AppID",escapedAppID];
    }
    
    
    if(properties != nil)
    {
        //TODO: kontrol et.
        [VisilabsPersistentTargetManager saveParameters:properties];
        NSString *additionalURL = [self urlizeProps:properties];
        if([additionalURL length] > 0)
        {
            segURL = [NSString stringWithFormat:@"%@%@", segURL,additionalURL];
        }
    }
    
    NSString *rtURL = nil;
    if(self.realTimeURL != nil && ![self.realTimeURL isEqualToString:@""] )
    {
        rtURL = [segURL stringByReplacingOccurrencesOfString:self.segmentURL withString:self.realTimeURL];
    }

    @synchronized(self)
    {
        [self.sendQueue addObject:segURL];
        if(rtURL != nil)
        {
            [self.sendQueue addObject:rtURL];
        }
    }
    [self send];
    
}

- (void)customEvent:(NSString *)pageName withProperties:(NSMutableDictionary *)properties
{
    if(pageName == nil || [pageName length] == 0)
    {
        DLog(@"Visilabs: WARNING - Tried to record event with empty or nil name. Ignoring.");
        return;
    }
    
    if ([[properties allKeys] containsObject:@"OM.cookieID"])
    {
        NSString *cookieid = [properties objectForKey: @"OM.cookieID"];
        
        if(![self.cookieID isEqualToString:cookieid]){
            [VisilabsPersistentTargetManager clearParameters];
        }
        
        self.cookieID = cookieid;
        if (![NSKeyedArchiver archiveRootObject:self.cookieID toFile:[self cookieIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive identity!!!");
        }
        [properties removeObjectForKey:@"OM.cookieID"];
    }
    
    if ([[properties allKeys] containsObject:@"OM.exVisitorID"])
    {
        NSString     *exvisitorid = [properties objectForKey: @"OM.exVisitorID"];
        
        if(![self.exVisitorID isEqualToString:exvisitorid]){
            [VisilabsPersistentTargetManager clearParameters];
        }
        
        if([self exVisitorID] != nil &&  ![[self exVisitorID] isEqualToString:exvisitorid])
        {
            [self setCookieID];
        }
        
        
        self.exVisitorID = exvisitorid;
        if (![NSKeyedArchiver archiveRootObject:self.exVisitorID toFile:[self exVisitorIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive new identity!!!");
        }
        [properties removeObjectForKey:@"OM.exVisitorID"];
    }
    
    if ([[properties allKeys] containsObject:@"OM.sys.TokenID"])
    {
        NSString *tokenid = [properties objectForKey: @"OM.sys.TokenID"];
        self.tokenID = tokenid;
        
        if (![NSKeyedArchiver archiveRootObject:self.tokenID toFile:[self tokenIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive tokenID!!!");
        }
        [properties removeObjectForKey:@"OM.sys.TokenID"];
    }
    
    if ([[properties allKeys] containsObject:@"OM.sys.AppID"])
    {
        NSString *appid = [properties objectForKey: @"OM.sys.AppID"];
        self.appID = appid;
        
        if (![NSKeyedArchiver archiveRootObject:self.appID toFile:[self appIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive appID!!!");
        }
        [properties removeObjectForKey:@"OM.sys.AppID"];
    }
    
    
    if ([[properties allKeys] containsObject:@"OM.m_adid"])
    {
        [properties removeObjectForKey:@"OM.m_adid"];
    }
    
    if ([[properties allKeys] containsObject:[VisilabsConfig APIVER_KEY]])
    {
        [properties removeObjectForKey:[VisilabsConfig APIVER_KEY]];
    }
    
    
    NSString *chan = self.channel;
    if ([[properties allKeys] containsObject:@"OM.vchannel"])
    {
        chan = [self urlEncode:[properties objectForKey: @"OM.vchannel"]];
        [properties removeObjectForKey:@"OM.vchannel"];
    }
    
    NSString *escapedPageName = [self urlEncode:pageName];
    
    
    
    int actualTimeOfevent = (int)[[NSDate date] timeIntervalSince1970];
    
    
    NSString *segURL = [NSString stringWithFormat:@"%@/%@/%@?%@=%@&%@=%@&%@=%@&%@=%@&%@=%i&%@=%@&%@=%@&%@=%@&%@=%@&", self.segmentURL,self.dataSource,@"om.gif"
                        ,@"OM.cookieID", self.cookieID
                        ,@"OM.vchannel", chan
                        ,@"OM.siteID",self.siteID
                        ,@"OM.oid",self.organizationID
                        ,@"dat", actualTimeOfevent
                        ,@"OM.uri",escapedPageName
                        ,@"OM.mappl",@"true"
                        ,@"OM.m_adid",self.identifierForAdvertising
                        ,[VisilabsConfig APIVER_KEY], @"IOS"];
    
    if(self.exVisitorID != nil &&  ![self.exVisitorID isEqual: @""])
    {
        NSString *escapedIdentity = [self urlEncode:self.exVisitorID];
        segURL = [NSString stringWithFormat:@"%@%@=%@",segURL,@"OM.exVisitorID",escapedIdentity];
    }
    
    if(self.tokenID != nil &&  ![self.tokenID isEqual: @""])
    {
        NSString *escapedToken = [self urlEncode:self.tokenID];
        segURL = [NSString stringWithFormat:@"%@&%@=%@",segURL,@"OM.sys.TokenID",escapedToken];
    }
    if(self.appID != nil &&  ![self.appID isEqual: @""])
    {
        NSString *escapedAppID = [self urlEncode:self.appID];
        segURL = [NSString stringWithFormat:@"%@&%@=%@",segURL,@"OM.sys.AppID",escapedAppID];
    }
    
    
    if(properties != nil)
    {
        //TODO: kontrol et.
        [VisilabsPersistentTargetManager saveParameters:properties];
        NSString *additionalURL = [self urlizeProps:properties];
        if([additionalURL length] > 0)
        {
            segURL = [NSString stringWithFormat:@"%@%@", segURL,additionalURL];
        }
    }
    
    NSString *rtURL = nil;
    if(self.realTimeURL != nil && ![self.realTimeURL isEqualToString:@""] )
    {
        rtURL = [segURL stringByReplacingOccurrencesOfString:self.segmentURL withString:self.realTimeURL];
    }
    
    if(self.checkForNotificationsOnLoggerRequest && self.actionURL != nil){
        [self showNotification:pageName properties:properties];
    }
    
    
    @synchronized(self)
    {
        [self.sendQueue addObject:segURL];
        if(rtURL != nil)
        {
            [self.sendQueue addObject:rtURL];
        }
    }
    [self send];
}

- (void)setProperties:(NSDictionary *)properties
{
    
    if(properties == nil || [properties count] == 0)
    {
        DLog(@"Visilabs: WARNING - Tried to set properties with no properties in it..");
        return;
    }
    
    NSString *additionalURL = [self urlizeProps:properties];
    if([additionalURL length] == 0)
    {
        DLog(@"Visilabs: WARNING - no valid properties in setProperties:. Ignoring call");
        return;
    }
    
    NSString *escapedIdentity = [self urlEncode:self.exVisitorID];
    
    NSString *escapedCookieID =[self urlEncode:self.cookieID];
    
    int actualTimeOfevent = (int)[[NSDate date] timeIntervalSince1970];
    
    NSString *theURL = [NSString stringWithFormat:@"%@/%@/%@?dat=%i&", self.segmentURL,self.dataSource, @"om.gif",actualTimeOfevent];
    
    if(escapedIdentity != nil && [escapedIdentity isEqualToString:@""] && [escapedIdentity length] !=0)
    {
        theURL = [NSString stringWithFormat:@"%@OM.exvisitorID=%@&",theURL, escapedIdentity];
    }
    
    theURL = [NSString stringWithFormat:@"%@OM.cookieID=%@&",theURL, escapedCookieID];
    
    theURL = [NSString stringWithFormat:@"%@%@", theURL,additionalURL];
    
    
    @synchronized(self)
    {
        [self.sendQueue addObject:theURL];
    }
    [self send];
}

- (void)login:(NSString *)exVisitorID  withProperties:(NSMutableDictionary *)properties
{
    if(exVisitorID == nil || [exVisitorID length] == 0)
    {
        DLog(@"Visilabs: WARNING - attempted to use nil or empty identity. Ignoring.");
        return;
    }
    else
    {
        if([self exVisitorID] != nil &&  ![[self exVisitorID]isEqualToString:exVisitorID])
        {
            [self setCookieID];
        }
        
        if(!properties)
        {
            properties = [[NSMutableDictionary alloc] init];
        }
        [properties setObject:exVisitorID forKey: [VisilabsConfig EXVISITORID_KEY]];
        [properties setObject:exVisitorID forKey: @"Login"];
        [properties setObject:@"Login" forKey: @"OM.b_login"];
        [self customEvent:@"LoginPage" withProperties:properties];
    }
}

- (void)signUp:(NSString *)exVisitorID  withProperties:(NSMutableDictionary *)properties
{
    if(exVisitorID == nil || [exVisitorID length] == 0)
    {
        DLog(@"Visilabs: WARNING - attempted to use nil or empty identity. Ignoring.");
        return;
    }
    else
    {
        if([self exVisitorID] != nil &&  ![[self exVisitorID] isEqualToString:exVisitorID])
        {
            [self setCookieID];
        }
        
        if(!properties)
        {
            properties = [[NSMutableDictionary alloc] init];
        }
        [properties setObject:exVisitorID forKey: [VisilabsConfig EXVISITORID_KEY]];
        [properties setObject:exVisitorID forKey: @"SignUp"];
        [properties setObject:@"SignUp" forKey: @"OM.b_sgnp"];
        [self customEvent:@"SignUpPage" withProperties:properties];
    }
}

- (void)login:(NSString *)exVisitorID
{
    
    if(exVisitorID == nil || [exVisitorID length] == 0)
    {
        DLog(@"Visilabs: WARNING - attempted to use nil or empty identity. Ignoring.");
        return;
    }
    
    if([self exVisitorID]!= nil &&  ![[self exVisitorID] isEqualToString:exVisitorID])
    {
        [self setCookieID];
    }
    
    NSString *escapedNewIdentity = [self urlEncode:exVisitorID];
    
    int actualTimeOfevent = (int)[[NSDate date] timeIntervalSince1970];
    
    NSString *escapedPageName = [self urlEncode:@"LoginPage"];
    
    
    NSString *segURL = [NSString stringWithFormat:@"%@/%@/%@?%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%i&%@=%@&%@=%@&%@=%@", self.segmentURL,self.dataSource,@"om.gif"
                        ,@"OM.vchannel", self.channel
                        ,@"OM.uri", escapedPageName
                        ,@"OM.cookieID", self.cookieID
                        ,@"OM.exVisitorID" ,escapedNewIdentity
                        ,@"OM.siteID",self.siteID
                        ,@"OM.oid",self.organizationID
                        ,@"OM.b_login", @"Login"
                        ,@"Login",escapedNewIdentity
                        ,@"dat", actualTimeOfevent
                        ,@"OM.mappl",@"true"
                        ,@"OM.m_adid",self.identifierForAdvertising
                        ,[VisilabsConfig APIVER_KEY], @"IOS"];
    
    
    
    if(self.tokenID != nil &&  ![self.tokenID isEqual: @""])
    {
        NSString *escapedToken = [self urlEncode:self.tokenID];
        segURL = [NSString stringWithFormat:@"%@&%@=%@",segURL,@"OM.sys.TokenID",escapedToken];
    }
    if(self.appID != nil &&  ![self.appID isEqual: @""])
    {
        NSString *escapedAppID = [self urlEncode:self.appID];
        segURL = [NSString stringWithFormat:@"%@&%@=%@",segURL,@"OM.sys.AppID",escapedAppID];
    }
    
    NSString *rtURL = nil;
    if(self.realTimeURL != nil && ![self.realTimeURL isEqualToString:@""] )
    {
        rtURL = [segURL stringByReplacingOccurrencesOfString:self.segmentURL withString:self.realTimeURL];
    }
    
    @synchronized(self)
    {
        if(![self.exVisitorID isEqualToString:exVisitorID]){
            [VisilabsPersistentTargetManager clearParameters];
        }
        
        self.exVisitorID = exVisitorID;
        
        if (![NSKeyedArchiver archiveRootObject:self.exVisitorID toFile:[self exVisitorIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive new identity!!!");
        }
        
        [self.sendQueue addObject:segURL];
        if(rtURL != nil)
        {
            [self.sendQueue addObject:rtURL];
        }
    }
    [self send];
    
}

- (void)signUp:(NSString *)exVisitorID
{
    
    if(exVisitorID == nil || [exVisitorID length] == 0)
    {
        DLog(@"Visilabs: WARNING - attempted to use nil or empty identity. Ignoring.");
        return;
    }
    
    if([self exVisitorID]!= nil &&  ![[self exVisitorID] isEqualToString:exVisitorID])
    {
        [self setCookieID];
    }
    
    NSString *escapedNewIdentity = [self urlEncode:exVisitorID];
    
    int actualTimeOfevent = (int)[[NSDate date] timeIntervalSince1970];
    
    NSString *escapedPageName = [self urlEncode:@"SignUpPage"];
    
    
    NSString *segURL = [NSString stringWithFormat:@"%@/%@/%@?%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%i&%@=%@&%@=%@&%@=%@", self.segmentURL,self.dataSource,@"om.gif"
                        ,@"OM.vchannel", self.channel
                        ,@"OM.uri", escapedPageName
                        ,@"OM.cookieID", self.cookieID
                        ,@"OM.exVisitorID" ,escapedNewIdentity
                        ,@"OM.siteID",self.siteID
                        ,@"OM.oid",self.organizationID
                        ,@"OM.b_sgnp", @"SignUp"
                        ,@"SignUp",escapedNewIdentity
                        ,@"dat", actualTimeOfevent
                        ,@"OM.mappl",@"true"
                        ,@"OM.m_adid",self.identifierForAdvertising
                        ,[VisilabsConfig APIVER_KEY], @"IOS"];
    
    if(self.tokenID != nil &&  ![self.tokenID isEqual: @""])
    {
        NSString *escapedToken = [self urlEncode:self.tokenID];
        segURL = [NSString stringWithFormat:@"%@&%@=%@",segURL,@"OM.sys.TokenID",escapedToken];
    }
    if(self.appID != nil &&  ![self.appID isEqual: @""])
    {
        NSString *escapedAppID = [self urlEncode:self.appID];
        segURL = [NSString stringWithFormat:@"%@&%@=%@",segURL,@"OM.sys.AppID",escapedAppID];
    }
    
    
    NSString *rtURL = nil;
    if(self.realTimeURL != nil && ![self.realTimeURL isEqualToString:@""] )
    {
        rtURL = [segURL stringByReplacingOccurrencesOfString:self.segmentURL withString:self.realTimeURL];
    }
    
    @synchronized(self)
    {
        if(![self.exVisitorID isEqualToString:exVisitorID]){
            [VisilabsPersistentTargetManager clearParameters];
        }
        
        
        self.exVisitorID = exVisitorID;
        
        if (![NSKeyedArchiver archiveRootObject:self.exVisitorID toFile:[self exVisitorIDFilePath]])
        {
            DLog(@"Visilabs: WARNING - Unable to archive new identity!!!");
        }
        
        [self.sendQueue addObject:segURL];
        if(rtURL != nil)
        {
            [self.sendQueue addObject:rtURL];
        }
    }
    [self send];
}

- (void)clearExVisitorID
{
    self.exVisitorID = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    DLog(@"Response URL: %@", [response.URL absoluteString]);
    
    if ([response statusCode] == 200 || [response statusCode] == 304)
    {
        @synchronized(self)
        {
            self.failureStatus = 0;
            if ([self.sendQueue count] > 0)
            {
                [self.sendQueue removeObjectAtIndex:0];
            }
            
            @try {
                 if (response.URL) {
                     NSString *urlString =[response.URL absoluteString];
                     if ([urlString containsString:[VisilabsConfig LOGGER_URL] options:NSCaseInsensitiveSearch]
                         || [urlString containsString:[VisilabsConfig REAL_TIME_URL] options:NSCaseInsensitiveSearch])
                     {
                         NSArray *cookies =[[NSArray alloc]init];
                         cookies = [NSHTTPCookie
                                    cookiesWithResponseHeaderFields:[response allHeaderFields]
                                    forURL:[NSURL URLWithString:[response.URL absoluteString]]]; // send to URL, return NSArray
                            for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
                            {
                                DLog(@"Cookie Key: %@", [cookie name]);
                                DLog(@"Cookie Value: %@", [cookie value]);
                                
                                if ([[cookie name] containsString:[VisilabsConfig LOAD_BALANCE_PREFIX] options:NSCaseInsensitiveSearch])
                                {
                                    if([urlString containsString:[VisilabsConfig REAL_TIME_URL] options:NSCaseInsensitiveSearch]){
                                        self.realTimeCookieKey = [cookie name];
                                        self.realTimeCookieValue = [cookie value];
                                    }else{
                                        self.loggerCookieKey = [cookie name];
                                        self.loggerCookieValue = [cookie value];
                                    }
                                }
                                
                                if ([[cookie name] containsString:[VisilabsConfig OM_3_KEY] options:NSCaseInsensitiveSearch])
                                {
                                    if([urlString containsString:[VisilabsConfig REAL_TIME_URL] options:NSCaseInsensitiveSearch]){
                                        self.realTimeOM3rdCookieValue = [cookie value];
                                    }else{
                                        self.loggerOM3rdCookieValue = [cookie value];
                                    }
                                }
                                
                            }
                         
                         
                         NSHTTPCookieStorage* afterCookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                         NSArray* existingCoookies = [afterCookies cookiesForURL:
                                                      [NSURL URLWithString:[response.URL absoluteString]]];
                         for (NSHTTPCookie* cookie in existingCoookies) {
                             [afterCookies deleteCookie:cookie];
                         }
                         
                     }
                 }
            }@catch(NSException *exception) {
                DLog(@"Visilabs: Error while reading cookie.");
            }
    
        }
    }
    else
    {
        DLog(@"Visilabs: INFO - Failure %@", [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]]);
        
        @synchronized(self)
        {
            self.failureStatus = [response statusCode];
            if ([self.sendQueue count] > 0)
            {
                [self.sendQueue removeObjectAtIndex:0];
            }
        }
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if(error.code == NSURLErrorBadURL ||
       error.code == NSURLErrorUnsupportedURL ||
       error.code == NSURLErrorDataLengthExceedsMaximum)
    {
        @synchronized(self)
        {
            if([self.sendQueue count] == 0)
            {
                DLog(@"Visilabs: CATASTROPHIC FAILURE (%@). Dropping call..",[error localizedDescription]);
            }
            else
            {
                DLog(@"Visilabs: CATASTROPHIC FAILURE (%@) for URL (%@). Dropping call..",[error localizedDescription], [self.sendQueue objectAtIndex:0]);
                [self.sendQueue removeObjectAtIndex:0];
            }
        }
    }
    
    @synchronized(self)
    {
        self.segmentConnection = nil;
        if ([self.sendQueue count] > 0)
        {
            //TODO:buna da gerek yok sanki
            //NSString *failedURL = [self.sendQueue objectAtIndex:0];
            //            [failedURL retain];
            [self.sendQueue removeObjectAtIndex:0];
            //            [failedURL release];
        }
    }
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    @synchronized(self)
    {
        self.segmentConnection = nil;
        
        if(self.failureStatus)
        {
            if(self.timer == nil)
            {
                self.timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                              target:self
                                                            selector:@selector(send)
                                                            userInfo:nil
                                                             repeats:NO];
            }
            
            return;
        }
    }
    
    [self send];
}

- (void)setCookieID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    self.cookieID =(__bridge NSString *)string;
    
    if (![NSKeyedArchiver archiveRootObject:self.cookieID toFile:[self cookieIDFilePath]])
    {
        DLog(@"Visilabs: WARNING - Unable to archive identity!!!");
    }
}

- (NSString *)getPushURL:(NSString *)source withCampaign:(NSString *)campaign withMedium:(NSString *)medium withContent:(NSString *)content
{
    int actualTimeOfevent = (int)[[NSDate date] timeIntervalSince1970];
    
    NSString *escapedPageName = [self urlEncode:@"/Push"];
    
    
    NSString *pushURL = [NSString stringWithFormat:@"%@/%@/%@/%@?%@=%@&%@=%@&%@=%@&%@=%@&%@=%i", self.RESTURL, self.encryptedDataSource , self.dataSource, self.cookieID
                         ,@"OM.vchannel", self.channel
                         ,@"OM.uri", escapedPageName
                         ,@"OM.siteID",self.siteID
                         ,@"OM.oid",self.organizationID
                         ,@"dat", actualTimeOfevent];
    
    if(self.exVisitorID != nil &&  ![self.exVisitorID isEqual: @""])
    {
        NSString *escapedIdentity = [self urlEncode:self.exVisitorID];
        pushURL = [NSString stringWithFormat:@"%@%@=%@",pushURL,@"&OM.exVisitorID",escapedIdentity];
    }
    
    if(source != nil &&  ![source isEqual: @""])
    {
        NSString *escapedSource = [self urlEncode:source];
        pushURL = [NSString stringWithFormat:@"%@%@=%@",pushURL,@"&utm_source",escapedSource];
    }
    if(campaign != nil &&  ![campaign isEqual: @""])
    {
        NSString *escapedCampaign = [self urlEncode:campaign];
        pushURL = [NSString stringWithFormat:@"%@%@=%@",pushURL,@"&utm_campaign",escapedCampaign];
    }
    if(medium != nil &&  ![medium isEqual: @""])
    {
        NSString *escapedMedium = [self urlEncode:medium];
        pushURL = [NSString stringWithFormat:@"%@%@=%@",pushURL,@"&utm_medium",escapedMedium];
    }
    if(content != nil &&  ![content isEqual: @""])
    {
        NSString *escapedContent = [self urlEncode:content];
        pushURL = [NSString stringWithFormat:@"%@%@=%@",pushURL,@"&utm_content",escapedContent];
    }
    
    return  pushURL;
}

-(void)setExVisitorIDToNull
{
    self.exVisitorID = nil;
}

@end



