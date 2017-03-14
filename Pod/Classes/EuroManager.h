//
//  EuroManager.m
//  EuroPush
//
//  Created by Ozan Uysal on 11/11/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMMessage.h"
#import "EMTools.h"
#import <UIKit/UIKit.h>

#define SDK_VERSION @"1.4"

@protocol EuroManagerDelegate <NSObject>

@required
- (void) didReceivePushMessage:(EMMessage *) message;

@optional
- (void) didReceiveImageMessage:(EMMessage *) message;
- (void) didReceiveVideoMessage:(EMMessage *) message;
- (void) didReceiveBackgroundMessage:(EMMessage *) message;
- (void) didRegisterSuccessfully;
- (void) didFailRegister:(NSError *) error;

@end

@interface EuroManager : NSObject {

}


@property (nonatomic, assign) id<EuroManagerDelegate> delegate;


+ (EuroManager *)sharedManager:(NSString *) applicationKey;

- (void) reportVisilabs: (NSString *) visiUrl;

- (void) setDebug:(BOOL) enable;

- (void) setUserEmail:(NSString *) email;
- (void) setUserKey:(NSString *) userKey;
- (void) setTwitterId:(NSString *) twitterId;
- (void) setFacebookId:(NSString *) facebookId;
- (void) setPhoneNumber:(NSString *) msisdn;
- (void) setAppVersion:(NSString *) appVersion;
- (void) setAdvertisingIdentifier:(NSString *) adIdentifier;
- (void) setUserLatitude:(double) lat andLongitude:(double) lon;
- (void) removeUserParameters;
- (void) addParams:(NSString *) key value:(id) value;


- (void) registerToken:(NSData *) tokenData;
- (void) handlePush:(NSDictionary *) pushDictionary;
//- (void) handlePush:(NSDictionary *) pushDictionary completionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
//- (void) handleInteractiveAction:(NSString *) actionIdentifier userInfo:(NSDictionary *) userInfo;

- (void) synchronize;

@end
