//
//  EuroManager.m
//  EuroPush
//
//  Created by Ozan Uysal on 11/11/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "EuroManager.h"
#import "EMLocation.h"
#import "EMBaseRequest.h"
#import "EMSettingsRequest.h"
#import "EMRegisterRequest.h"
#import "EMRetentionRequest.h"

#import "EMConnectionManager.h"

#define TOKEN_KEY @"EURO_TOKEN_KEY"
#define REGISTER_KEY @"EURO_REGISTER_KEY"
#define LAST_REQUEST_DATE_KEY @"EURO_LAST_REQUEST_DATE_KEY"

static NSString * const EURO_KEYID_KEY = @"keyID";
static NSString * const EURO_MSISDN_KEY = @"msisdn";
static NSString * const EURO_EMAIL_KEY = @"email";
static NSString * const EURO_LOCATION_KEY = @"location";
static NSString * const EURO_FACEBOOK_KEY = @"facebook";
static NSString * const EURO_TWITTER_KEY = @"twitter";
static NSString * const EURO_LAST_MESSAGE_KEY = @"em.lastMessage";

static NSString * const EURO_RECEIVED_STATUS = @"D";
static NSString * const EURO_READ_STATUS = @"O";

@interface EuroManager()

@property (nonatomic, assign) BOOL debugMode;
@property (nonatomic, strong) __block EMRegisterRequest *registerRequest;

- (void) reportRetention:(EMMessage *) message status:(NSString *) status;
- (void) reportDelegate:(EMMessage *) message;


@end

@implementation EuroManager

@synthesize delegate;

#pragma mark Private methods

- (void) reportDelegate:(EMMessage *) message {
    // report delegate for the message received with respect to message type
    if([message.pushType isEqualToString:@"Text"]) {
        [self.delegate didReceivePushMessage:message];
    } else if ([message.pushType isEqualToString:@"Image"]) {
        if([self.delegate respondsToSelector:@selector(didReceiveImageMessage:)]) {
            [self.delegate didReceiveImageMessage:message];
        }
    } else if ([message.pushType isEqualToString:@"Video"]) {
        if([self.delegate respondsToSelector:@selector(didReceiveVideoMessage:)]) {
            [self.delegate didReceiveVideoMessage:message];
        }
    } else if ([message.pushType isEqualToString:@"Settings"]) {
        /*[self loadSettings:^(BOOL finished) {
         
         }];*/
    }
}

- (void) reportVisilabs : (NSString *) visiUrl {
    
    [[EMConnectionManager sharedInstance] request:visiUrl];
    
}

- (void) reportRetention:(EMMessage *) message status:(NSString *)status {
    
    if(message.pushId == nil) {return;}
    
    if(self.debugMode) {
        LogInfo(@"reportRetention: %@",message.toDictionary);
    }
    
    EMRetentionRequest *rRequest = [EMRetentionRequest new];
    rRequest.key = self.registerRequest.appKey;
    rRequest.token = self.registerRequest.token;
    rRequest.status = status;
    rRequest.pushId = message.pushId;
    rRequest.choiceId = @"";
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[EMConnectionManager sharedInstance] request:rRequest success:^(id response) {
            // retention report success
            [EMTools removeUserDefaults:EURO_LAST_MESSAGE_KEY];
            
        } failure:^(NSError *error) {
            
        }];
    });
}

#pragma mark Singleton Methods

+ (EuroManager *)sharedManager:(NSString *) applicationKey {
    static EuroManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
        sharedMyManager.registerRequest.token = [EMTools retrieveUserDefaults:TOKEN_KEY];
    });
    sharedMyManager.registerRequest.appKey = applicationKey;
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        // set the register request object ready
        self.registerRequest = [EMRegisterRequest new];
        NSString *lastRegister = [NSString stringWithFormat:@"%@",[EMTools retrieveUserDefaults:REGISTER_KEY]];
        NSError *jsonError = nil;
        EMRegisterRequest *lastRequest = [[EMRegisterRequest alloc] initWithString:lastRegister error:&jsonError];
        if(jsonError == nil) {
            self.registerRequest.extra = lastRequest.extra;
        }
        self.registerRequest.sdkVersion = SDK_VERSION;
        // set the observers ready - update user information on every application close
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronize)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronize)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(synchronize)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationDidEnterBackgroundNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillTerminateNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationDidBecomeActiveNotification];
}

#pragma mark public methods
#pragma mark user information
/*
 - (void) setBackgroundHandler:(id) handler {
 _backgroundHandler = handler;
 }
 */
- (void) setAdvertisingIdentifier:(NSString *) adIdentifier {
    self.registerRequest.advertisingIdentifier = adIdentifier;
}

- (void) setAppVersion:(NSString *) appVersion {
    self.registerRequest.appVersion = appVersion;
}

- (void) setDebug:(BOOL) enable {
    self.debugMode = enable;
    [EMConnectionManager sharedInstance].debugMode = enable;
}

- (void) synchronize {
    
    // check whether the user have an unreported message
    NSString *messageJson = [EMTools retrieveUserDefaults:EURO_LAST_MESSAGE_KEY];
    if(messageJson) {
        
        LogInfo(@"Old message : %@",messageJson);
        
        NSError *jsonError;
        EMMessage *lastMessage = [[EMMessage alloc] initWithString:messageJson usingEncoding:NSUTF8StringEncoding error:&jsonError];
        if(!jsonError) {
            [self reportRetention:lastMessage status:EURO_READ_STATUS];
        }
    }
    
    __block NSString *currentRegister = self.registerRequest.toJSONString;
    NSString *lastRegister = [NSString stringWithFormat:@"%@",[EMTools retrieveUserDefaults:REGISTER_KEY]];
    
    if ([EMTools retrieveUserDefaults:TOKEN_KEY]) { // set whether it is the first request or not
        self.registerRequest.firstTime = [NSNumber numberWithInt:0];
    }
    
    if (self.debugMode) {
        LogInfo(@"Current registration settings %@",currentRegister);
    }
    
    [EMTools saveUserDefaults:TOKEN_KEY andValue:self.registerRequest.token]; // save the token just in case
    
    NSDate *now = [NSDate date];
    NSDate *fiveMinsLater = [NSDate dateWithTimeInterval:15 * 60 sinceDate:now]; // check every 15 minutes
    
    if(![[EMTools getInfoString:@"CFBundleIdentifier"] isEqualToString:@"com.euromsg.EuroFramework"]) {
        
        NSComparisonResult result = [now compare:[EMTools retrieveUserDefaults:LAST_REQUEST_DATE_KEY]];
        if ((result == NSOrderedAscending && [lastRegister isEqualToString:currentRegister]) || self.registerRequest.token == nil) {
            if (self.debugMode) {
                LogInfo(@"Register request not ready : %@",self.registerRequest.toDictionary);
            }
            return;
        }
    }
    
    if(self.registerRequest.appKey == nil || [@"" isEqual:self.registerRequest.appKey]) { return; } // appkey should not be empty
    
    __weak __typeof__(self) weakSelf = self;
    [[EMConnectionManager sharedInstance] request:self.registerRequest success:^(id response) {
        
        [EMTools saveUserDefaults:LAST_REQUEST_DATE_KEY andValue:fiveMinsLater]; // save request date
        
        [EMTools saveUserDefaults:REGISTER_KEY andValue:currentRegister];
        
        if (weakSelf.debugMode) {
            LogInfo(@"Token registered to EuroMsg : %@",self.registerRequest.token);
        }
        
        if([weakSelf.delegate respondsToSelector:@selector(didRegisterSuccessfully)]) {
            [weakSelf.delegate didRegisterSuccessfully];
        }
        
    } failure:^(NSError *error) {
        if (weakSelf.debugMode) {
            LogInfo(@"Request failed : %@",error);
        }
        if([weakSelf.delegate respondsToSelector:@selector(didFailRegister:)]) {
            [weakSelf.delegate didFailRegister:error];
        }
    }];
    
}

- (void) setUserEmail:(NSString *) email {
    if([EMTools validateEmail:email]) {
        [self.registerRequest.extra setObject:email forKey:EURO_EMAIL_KEY];
    }
}

- (void) addParams:(NSString *) key value:(id) value {
    if(value) {
        [self.registerRequest.extra setObject:value forKey:key];
    }
}

- (void) setUserKey:(NSString *) userKey {
    if(userKey) {
        [self.registerRequest.extra setObject:userKey forKey:EURO_KEYID_KEY];
    }
}

- (void) setTwitterId:(NSString *) twitterId {
    if(twitterId) {
        [self.registerRequest.extra setObject:twitterId forKey:EURO_TWITTER_KEY];
    }
}

- (void) setFacebookId:(NSString *) facebookId {
    if(facebookId) {
        [self.registerRequest.extra setObject:facebookId forKey:EURO_FACEBOOK_KEY];
    }
}

- (void) setPhoneNumber:(NSString *) msisdn {
    if([EMTools validatePhone:msisdn]) {
        [self.registerRequest.extra setObject:msisdn forKey:EURO_MSISDN_KEY];
    }
}

- (void) setUserLatitude:(double) lat andLongitude:(double) lon {
    EMLocation *location = [EMLocation new];
    location.latitude = [NSNumber numberWithDouble:lat];
    location.longitude = [NSNumber numberWithDouble:lon];
    [self.registerRequest.extra setObject:location.toDictionary forKey:EURO_LOCATION_KEY];
}

- (void) addCustomUserParameter:(NSString *) key value:(id) value {
    if (key && value) {
        [self.registerRequest.extra setObject:value forKey:key];
    }
}

- (void) removeUserParameters {
    [self.registerRequest.extra removeAllObjects];
}

#pragma mark API Related

- (void) registerToken:(NSData *) tokenData {
    
    if(tokenData == nil) {
        LogInfo(@"Token data cannot be nil");
        return;
    }
    
    NSString *tokenString = [[[tokenData description] stringByTrimmingCharactersInSet:
                              [NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                             stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if(self.debugMode) {
        LogInfo(@"Your token is %@",tokenString);
    }
    
    self.registerRequest.token = tokenString;
    
    [self synchronize];
    
}

/*
- (void) handleInteractiveAction:(NSString *) actionIdentifier userInfo:(NSDictionary *) userInfo {
    
    NSError *parseError;
    EMMessage *message = [[EMMessage alloc] initWithDictionary:userInfo error:&parseError];
    
    //[self reportDelegate:message];
    
    if (!parseError) {
        EMRetentionRequest *rRequest = [EMRetentionRequest new];
        rRequest.key = self.registerRequest.appKey;
        rRequest.token = self.registerRequest.token;
        rRequest.status = EURO_READ_STATUS;
        rRequest.pushId = message.pushId;
        rRequest.choiceId = actionIdentifier;
        
        [[EMConnectionManager sharedInstance] request:rRequest success:^(id response) {
            // retention report success
            
        } failure:^(NSError *error) {
            // retention report fail
            
        }];
    }
}
*/

- (void) handlePush:(NSDictionary *) pushDictionary {
    
    if(pushDictionary == nil || [pushDictionary objectForKey:@"pushId"] == nil) {
        return;
    }
    
    if(self.debugMode) {
        LogInfo(@"handlePush: %@",pushDictionary);
    }
    
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    
    NSError *error;
    EMMessage *message = [[EMMessage alloc] initWithDictionary:pushDictionary error:&error];
    
    if (state != UIApplicationStateActive) {
        [EMTools saveUserDefaults:EURO_LAST_MESSAGE_KEY andValue:message.toJSONString];
    } else {
        if (!error) {
            // report retention
            [self reportRetention:message status:EURO_READ_STATUS];
            
            [self reportDelegate:message];
        }
    }
}

/*
 - (void) handlePush:(NSDictionary *) pushDictionary completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
 
 UIApplicationState state = [UIApplication sharedApplication].applicationState;
 [[EMConnectionManager sharedInstance] setResponseBlock:completionHandler];
 
 if(pushDictionary == nil || [pushDictionary objectForKey:@"pushId"] == nil) {
 completionHandler(UIBackgroundFetchResultFailed);
 return;
 }
 
 if(self.debugMode) {
 LogInfo(@"New push received %@",pushDictionary);
 }
 
 NSError *parseError;
 EMMessage *message = [[EMMessage alloc] initWithDictionary:pushDictionary error:&parseError];
 
 if (!parseError) {
 // if background settings are received just read them and return
 if ([message.contentAvailable boolValue] && message.pushType == nil && message.pushId == nil)  {
 [self registerInteractiveSettings:[message getInteractiveSettings]];
 return;
 }
 
 if (state != UIApplicationStateActive) {
 
 // report retention
 [self reportRetention:message status:EURO_RECEIVED_STATUS];
 
 [self reportDelegate:message];
 
 completionHandler(UIBackgroundFetchResultNoData);
 } else {
 [self handlePush:pushDictionary];
 }
 } else {
 completionHandler(UIBackgroundFetchResultFailed);
 }
 }
 */

- (void) registerInteractiveSettings : (NSDictionary *) settingsDictionary {
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        if(settingsDictionary != nil) {
            id category = settingsDictionary;
            // don't forget old category settings
            NSMutableSet *categorySet = [NSMutableSet setWithSet:[[[UIApplication sharedApplication] currentUserNotificationSettings] categories]];
            
            // if the same id exists before remove it
            __block id oldNotificationCategory = nil;
            [categorySet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                UIUserNotificationAction *action = (UIUserNotificationAction *) obj;
                if ([action.identifier isEqual:[category objectForKey:@"id"]]) {
                    oldNotificationCategory = obj;
                }
            }];
            // remove the old setting
            if(oldNotificationCategory) {
                [categorySet removeObject:oldNotificationCategory];
            }
            
            // add new interactive setting
            id actions = [category objectForKey:@"actions"];
            NSMutableArray *actionArray = [NSMutableArray new];
            for (id action in actions) {
                UIMutableUserNotificationAction *notificationAction = [UIMutableUserNotificationAction new];
                notificationAction.identifier = [action objectForKey:@"identifier"];
                notificationAction.title = [action objectForKey:@"title"];
                notificationAction.activationMode = [[action objectForKey:@"activationMode"] intValue];
                notificationAction.destructive = [[action objectForKey:@"destructive"] boolValue];
                notificationAction.authenticationRequired = [[action objectForKey:@"authenticationRequired"] boolValue];
                [actionArray addObject:notificationAction];
            }
            
            UIMutableUserNotificationCategory *notificationCategory = [[UIMutableUserNotificationCategory alloc] init];
            notificationCategory.identifier = [category objectForKey:@"id"];
            [notificationCategory setActions:actionArray forContext:UIUserNotificationActionContextDefault];
            [notificationCategory setActions:actionArray forContext:UIUserNotificationActionContextMinimal];
            [categorySet removeObject:notificationCategory];
            [categorySet addObject:notificationCategory];
            
            UIUserNotificationType notificationType = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
            UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:notificationType categories:categorySet];
            
            [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
        }
    }
}


@end