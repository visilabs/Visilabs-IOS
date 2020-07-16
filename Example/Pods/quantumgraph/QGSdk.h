//
//  QGSdk.h
//  QGSdk
//
//  Created by Shiv
//  Copyright (c) 2019 APPIER INC. All rights reserved.
//  SDK VERSION ---> 5.2.1
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "QGInbox.h"

NS_ASSUME_NONNULL_BEGIN
@interface QGSdk : NSObject

/*!
 @abstract
 Flush timer's interval.
 
 @discussion
 Setting a flush interval of 0 will turn off the flush timer.
 
 @note Default to 1 sec in Dev and 15 secs in Release
 */
@property (atomic) NSUInteger flushInterval;

/*!
 @discussion
 Restrict external init calls and allow to use singleton.
 */
-(instancetype) init __attribute__((unavailable("Please use `+ (QGSdk *)getSharedInstance;` instead")));

/*!
 @discussion
 Initialises QGSdk and returns the shared instance of the sdk,
 to access all the methods of the sdk
 
 @result QGSdk instance
 */
+ (QGSdk *) getSharedInstance;

/*!
 @abstract
 Set the app id and profile to setup sdk
 
 @discussion
 This initialises the sdk with your app id.
 Add this method to you AppDelegate applicaiton:didFinishLaunchingWithOptions:
 You can find it your account on app.qgraph.io in setup.
 
 @param appId           your QGraph account appId
 @param devProfile      True/Yes for Development and False/No for Production
 */
- (void)onStart:(NSString *)appId setDevProfile:(BOOL)devProfile;

/*!
 @abstract
 Set the app id, app group and profile to setup sdk
 
 @discussion
 Same as 'onStart:setDevProfile' with App Group options.
 Use this onStart method if you wish to add content & service extension of QGraph.
 App Group will help to share data between app target and extensions.
 App Group is 'Required' to log events from extension and also to track
 certain events from the rich push notification.
 
 @param appId           your QGraph account appId
 @param appGroup        APP-GROUP used for the service & content extension and app target
 @param devProfile      True/Yes for Development and False/No for Production
 
 @note Pass appGroup as 'nil' if not using rich push (Carousel/Slider Push)
 @note However this appGroup also helps track ctr for the push notification using service extension.
 */
- (void)onStart:(NSString *)appId withAppGroup:(nullable NSString *)appGroup setDevProfile:(BOOL)devProfile;

/*!
 @method
 
 @abstract
 Register UNNotificationCategory for Carousel Action Buttons.
 
 @discussion
 Registers the UNNotificationCategory for custom notification(Carousel) with the action buttons.
 If there are no action buttons, this method can be used to directly register the carousel actions.
 If there are other action category to be registered, get the QGCAROUSEL category and
 register along with other categories. Use `getQGSliderPushActionCategoryWithNextButtonTitle` method.
 By default, sdk will register this with deault buttons.
 
 iOS 11 and below has Next button (to scroll item) and open app button (for deeplink).
 iOS 12 and above, user interaction is enabled, so only open app button is shown.
 
 @param next            optional next button title, default to '▶▶' (iOS 11 and below)
 @param openApp         optional open app button title, default to 'Open App'
 
 @code
 [QGSdk setCarouselNotificationCategoryWithNextButtonTitle:nil withOpenAppButtonTitle:nil];
 
 [QGSdk setCarouselNotificationCategoryWithNextButtonTitle:@"Next" withOpenAppButtonTitle:@"Check Out"];
 @endcode
 
 */
+ (void)setCarouselNotificationCategoryWithNextButtonTitle:(nullable NSString *)next withOpenAppButtonTitle:(nullable NSString *)openApp API_AVAILABLE(ios(10.0));

/*!
 @method
 
 @abstract
 Register UNNotificationCategory for Carousel Action Buttons.
 
 @discussion
 Registers the UNNotificationCategory for custom notification(Carousel) with the action buttons. If you have other notification action category, add along with this category. By default, sdk will register this with deault buttons.
 
 iOS 11 and below has Next button (to scroll item) and open app button (for deeplink).
 iOS 12 and above, user interaction is enabled, so only open app button is shown.
 
 @param next            optional next button title, default to '▶▶' (iOS 11 and below)
 @param openApp         optional open app button title, default to 'Open App'
 
 @code
 [QGSdk getQGSliderPushActionCategoryWithNextButtonTitle:nil withOpenAppButtonTitle:nil];
 
 [QGSdk getQGSliderPushActionCategoryWithNextButtonTitle:@"Next" withOpenAppButtonTitle:@"Check Out"];
 @endcode
 
 */
+ (UNNotificationCategory *)getQGSliderPushActionCategoryWithNextButtonTitle:(nullable NSString *)next withOpenAppButtonTitle:(nullable NSString *)openApp API_AVAILABLE(ios(10.0));

/*!
 @abstract
 Set the Associated Domains for Universal

 @param domains         The Associated Domains

 @note For example: [[QGSdk getSharedInstance] setUniversalLinkDomains:@[@"first.domain.com", @"second.domain.com]];
 */
- (void)setUniversalLinkDomains:(NSArray <NSString *> *)domains;

/*! This method is not used currently */
- (void)onStop;

/*!
 @abstract
 Returns boolean to show push prompt
 
 @discussion
 You can use this value to determine when to show push prompt.
 Since iOS 12, you can send silent push without push permission until user turn off the notification.
 After sending some silent push, you can decide if you want to show push prompt based on user activity on your app.
 
 @note If not set, default value is true
 
 */
- (BOOL)getShowPushPrompt;

/*!
 @abstract
 Sends the APNS token to QGraph Server
 
 @discussion
 Set the Device Token received from APNS in the AppDelegate.
 This method is required to identify device for sending push notification.
 
 @note Implement this in @code application:didRegisterForRemoteNotificationsWithDeviceToken: @endcode to setToken
 */
- (void)setToken:(NSData *)tokenData;

/*!
 @abstract
 Set the unique user id for your users
 
 @discussion
 you can identify your user with user_id while creating segment on app.qgraph.io
 */
- (void)setUserId:(NSString *)userId;

/*! @abstract Set the name of the user */
- (void)setName:(NSString *)name;

/*! @abstract Set the first name of the user */
- (void)setFirstName:(NSString *)name;

/*! @abstract Set the last name of the user */
- (void)setLastName:(NSString *)name;

/*! @abstract Set the city of the user */
- (void)setCity:(NSString *)city;

/*! @abstract Set the email id of the user */
- (void)setEmail:(NSString *)email;

/*! @abstract Set the day of DOB of the user */
- (void)setDayOfBirth:(NSNumber *)day;

/*! @abstract Set the month of DOB of the user */
- (void)setMonthOfBirth:(NSNumber *)month;

/*! @abstract Set the year of DOB of the user */
- (void)setYearOfBirth:(NSNumber *)year;

/*!
 @abstract
 Set any custom key for your user
 
 @discussion
 Use this method to set any custom key for the user.
 Suppose you want to set rating of the user.
 
 @code setCustomKey:@"rating" withValue:3.5 @endcode
 */
- (void)setCustomKey:(NSString *)key withValue:(id)value;

/*!
 @abstract
 Sends any event in your app to the QGraph server
 
 @discussion
 This methods help you track any particular event.
 for example, viewing the products, playing a game or listening to a music
 
 eg: logEvent:@"product_viewed"
 
 @param name            name of the event
 */
- (void)logEvent:(NSString *)name;

/*!
 @abstract
 Track any event in your app with custom parameter
 
 @discussion
 Same as logEvent: but with some parameter in form of dictionary.
 You can pass custom parameter for the particular event.
 
 eg: for event: product_viewed, you want to track name of the product, brand, image url or any other details.
 
 @note use valid data types in dictionary
 
 @param name            name of the event
 @param parameters      dictionary of all the parameter for the event
 */
- (void)logEvent:(NSString *)name withParameters:(nullable NSDictionary *)parameters;

/*!
 @abstract
 Track any event in your app with monetary value associated to it
 
 @discussion
 eg: for event: product_viewed, price of the product is Rs 50
 
 @note Use value in the form of NSNumber
 
 @param name            name of the event
 @param valueToSum      monetary value (NSNumber) associated to the event
 */
- (void)logEvent:(NSString *)name withValueToSum:(nullable NSNumber *)valueToSum;

/*!
 @abstract
 Track any event in your app with monetary value associated to it along with its currency
 
 @discussion
 eg: for event: product_viewed, price of the product is 50 INR or 1 USD
 
 @note Use value in the form of NSNumber and 3 character currency code
 
 @param name            name of the event
 @param valueToSum      monetary value (NSNumber) associated to the event
 @param vtsCurr         currency code of the value to sum
 */
- (void)logEvent:(NSString *)name withValueToSum:(nullable NSNumber *)valueToSum withValueToSumCurrency:(nullable NSString *)vtsCurr;

/*!
 @abstract
 Track any event in your app with custom parameters and monetary value associated to it
 
 @discussion
 Combination of logEvent:withParameter and logEvent:valueToSum
 
 @param name            name of the event
 @param parameters      dictionary of all the parameter for the event
 @param valueToSum      monetary value (NSNumber) associated to the event
 */
- (void)logEvent:(NSString *)name withParameters:(nullable NSDictionary *)parameters withValueToSum:(nullable NSNumber *) valueToSum;

/*!
 @abstract
 Track any event in your app with custom parameters and monetary value associated to it along with its currency
 
 @discussion
 Combination of logEvent:withParameter and logEvent:withValueToSum:withValueToSumCurrency
 
 @param name            name of the event
 @param parameters      dictionary of all the parameter for the event
 @param valueToSum      monetary value (NSNumber) associated to the event
 @param vtsCurr         currency code of the value to sum
 */
- (void)logEvent:(NSString *)name withParameters:(nullable NSDictionary *)parameters withValueToSum:(nullable NSNumber *) valueToSum withValueToSumCurrency:(nullable NSString *)vtsCurr;

/*!
 @abstract
 Convert the parameters into several events for tracking.
 
 @discussion
 Combination of logEvent:withParameter and logEvent:withValueToSum:withValueToSumCurrency:withConvertedEvent:withAttributeEnable
 
 @param name            name of the event
 @param parameters      dictionary of all the parameter for the event
 @param valueToSum      monetary value (NSNumber) associated to the event
 @param vtsCurr         currency code of the value to sum
 @param convertedEventName    name of multi-parameters event
 @param enabled         enabled / disabled sending attribution info
 */
- (void)logEvent:(NSString *)name withParameters:(NSDictionary *)parameters withValueToSum:(nullable NSNumber *)valueToSum withValueToSumCurrency:(nullable NSString *)vtsCurr withConvertedEvent:(nullable NSString *)convertedEventName withAttributionEnabled:(BOOL)enabled;

/*!
 @abstract
 Sets the Click Through Attribution Window for event attribution
 
 @discussion
 This method should be used to set the click through attribution window.
 Click through works for push notification (sent by QGraph) clicks and InApp Notification clicks.
 Default to 24 hrs (86400 secs).
 
 eg: for click attribution window to be 12 hrs, pass the value: 43200
 
 @note Pass seconds as '0' to disable click attribution
 
 @param seconds         attribution window time in seconds
 */
- (void)setClickAttributionWindow:(NSInteger)seconds;

/*!
 @abstract
 Sets the View Through Attribution Window for event attribution
 
 @discussion
 This method should be used to set the View through attribution window.
 View through attribution works only for InApp notifications.
 Default to 1 hr (3600 secs).
 
 eg: for view through attribution window to be 2 hrs, pass the value: 7200
 
 @note Pass seconds as '0' to disable view through attribution
 
 @param seconds         attribution window time in seconds
 */
- (void)setAttributionWindow:(NSInteger)seconds;

/*!
 @abstract
 Disables In-App campaigns
 
 @discussion
 This method allows to enable and disable InApp campaigns to be delivered to device
 By default it is enabled, set 'YES' to disable it
 Disabling it will prevent device to get any new InApp Campaigns
 
 @note Use @code disableInAppCampaigns:YES @endcode to Disable
 */
- (void)disableInAppCampaigns:(BOOL)disabled;

/*!
 @abstract
 Tracks application launch finish
 
 @discussion
 Add this method to your AppDelegate applicaiton:didFinishLaunchingWithOptions:
 */
- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

/*!
 @abstract
 Captures the push notification sent by QGraph server
 
 @discussion
 Add to your AppDelegate application:didReceiveRemoteNotification:fetchCompletionHandler:
 pass all the push notifications received by the app
 This method also let the sdk track app_launched event due to click on the notification sent by QGraph
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

/*!
 @abstract
 Captures the push notification delivered in foreground.
 
 @discussion
 Add to your AppDelegate or class implementing your UNNotificationCenterDelegate methods.
 @code
 [[QGSdk getSharedInstance] userNotificationCenter:center willPresentNotification:notification];
 @endcode
 
 The delegate method can be used to show the notification alert in the foreground State.
 In your completion handler, pass your UNNotificationPresentationOptions.
 
 For eg:
 @code
 UNNotificationPresentationOptions option = UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert;
 completionHandler(option);
 @endcode
 
 */
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification API_AVAILABLE(ios(10.0));

/*!
 @abstract
 Captures the push notification clicked event.
 
 @discussion
 Add to your AppDelegate or class implementing your UNNotificationCenterDelegate methods.
 
 The method will be called on the delegate when the user responded to the notification by opening the application or choosing a UNNotificationAction.
 
 @code
 [[QGSdk getSharedInstance] userNotificationCenter:center didReceiveNotificationResponse:response];
 @endcode
 */
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response API_AVAILABLE(ios(10.0));

/*!
 @abstract
 Uploads queued data to the QGraph server.
 
 @discussion
 By default, queued data is flushed to the QGraph servers every 15 seconds (the
 default for flushInterval). You only need to call this
 method manually if you want to force a flush at a particular moment.
 */
- (void)flush;

/*!
 @abstract
 Calls flush, then calls a handler when finished.
 
 @discussion
 When calling flush manually, it is sometimes important to verify
 that the flush has finished before further action is taken.
 */
- (void)flushWithCompletion:(void (^)(void))handler;

/*!
 @abstract
 Returns recommendation data for the user based on User to Product AI Model without Category Filter
 
 @discussion
 This is a asynchronous function which returns array of recommended objects
 based on User To Product AI Model without filtering any category from the product data feed.
 Parse the response object and use it as required
 */
- (void)getRecommendationForModelUserToProductWithCompletion:(void (^)(NSArray *response))completion;

/*!
 @abstract
 Returns recommendation data for the user based on User to Product AI Model with Some Category Filter

 @discussion
 This is a asynchronous function which returns array of recommended objects
 based on User To Product AI Model with filtering a specified product category with sub-category and sub-sub-category.
 
 For Example: Filter with following categories
 Cateory - Clothing
 Sub-Category - Men
 Sub-Sub-Category - Shirts
 
 @code
 [[QGSdk getSharedInstance] getRecommendationForModelUserToProductWithCategory:@"Clothing" withSubCategory:@"Men" withSubSubCategory:@"Shirts" withCompletion:^(NSArray * _Nonnull response) {
    NSLog(@"Recommendation Response:%@", response);
 }];
 @endcode
 
 Parse the response object and use it as required
*/
- (void)getRecommendationForModelUserToProductWithCategory:(NSString * _Nullable)category withSubCategory:(NSString * _Nullable)subCategory withSubSubCategory:(NSString * _Nullable)subSubCategory withCompletion:(void (^)(NSArray *response))completion;

/*!
 @abstract
 Fetch the latest remote inboxMessages
 
 @discussion
 This is an asynchronous function to get the latest messages from servers. In the completionHandler,
 we could call getInboxesWithStatusRead:(BOOL)read statusUnread:(BOOL)unread statusDeleted:(BOOL)deleted to
 get the most recent messages if success is true. If success is false, we could still get the existingly local saved messages
 
 @code
 [[QGSdk getSharedInstance] fetchInboxMessages:^(BOOL success, NSError * _Nullable error) {
    if (success) {
        NSArray <QGInbox *> *inboxList = [[QGSdk getSharedInstance] getInboxesWithStatusRead:YES statusUnread:YES statusDeleted:YES];
    }
 }];
 @endcode
 */
- (void)fetchInboxMessages:(void (^)(BOOL success, NSError * _Nullable error))completionHandler;

/*!
 @abstract
 Returns inboxMessages from local storage.
 
 @discussion
 This is a synchronous function which immediately returns array of inbox objects
 
 @code
 Get messages with status Deleted, ex:
 NSArray <QGInbox *> *inboxList = [[QGSdk getSharedInstance] getInboxesWithStatusRead:NO read statusUnread:NO statusDeleted:YES];
 
 Get messages with status Read or Deleted, ex:
 NSArray <QGInbox *> *inboxList = [[QGSdk getSharedInstance] getInboxesWithStatusRead:YES statusUnread:NO statusDeleted:YES];
 @endcode
 */
- (NSArray<QGInbox *> *)getInboxesWithStatusRead:(BOOL)read statusUnread:(BOOL)unread statusDeleted:(BOOL)deleted;

/*!
 @abstract
 Update the limit of inboxMessage
 
 @discussion
 This will update the number of limit for storage of inbox message. Then check if current count of inbox
 message exceeds this new limit. If exceeds, older records in the existing inbox messages will be removed.
 
 @param limit             the limit to change (QGInboxLimitSmall, QGInboxLimitMedium, QGInboxLimitHigh, QGInboxLimitExtraHigh)
 
 @code
 Update the inbox limit to QGInboxLimitHigh, ex: [[QGSdk getSharedInstance] updateInboxRecordLimit:QGInboxLimitHigh];
 @endcode
 */
- (void)updateInboxRecordLimit:(QGInboxLimit) limit;

/*!
@abstract
Get locally saved push notification data, which is a list of notification payload

@discussion
Whenever we received push notification, we save the payload in the local storage
 
@code
NSArray *payloadList = [QGSdk getSharedInstance] fetchSavedPushNotifications];
@endcode
*/
- (NSArray*)fetchSavedPushNotifications;

/*!
@abstract
Remove all local-saved push notification data

@discussion
Clean all local-saved push notification data if we don't need it
 
@code
[QGSdk getSharedInstance] deleteSavedPushNotifications];
@endcode
*/
- (void)deleteSavedPushNotifications;

/*!
@abstract
Remove one specific local-saved push notification

@discussion
We just need to remove one specific local-saved push notification
 
@code
[QGSdk getSharedInstance] deleteNotificationAtIndex:index];
@endcode
*/
- (void)deleteNotificationAtIndex:(NSUInteger)index;

/*!
@abstract
Enable or Disable Remote Push Notification Storage

@discussion
This method can be used to enable or disable storage of Remote
Push Notification which are sent only from AIQUA Server.

By default, it is @b DISABLED.
 
@note QGNotificationSdk (Version 5.2.1 and above) i.e. Rich push @b MUST be integrated
 
@code
[QGSdk getSharedInstance] enablePushNotificationStorage];
@endcode
*/
- (void)enablePushNotificationStorage;

/*!
@abstract
 Set the maxinum number of rows to save push notification

@discussion
 This is the maximum number (Default to 20) of latest notifications received from AIQUA server will be stored by the sdk.
 If the limit you set is smaller than the existing limit, for example changing from 100 to 80, the older 20 notifications will be deleted.
 
@code
[QGSdk getSharedInstance] setPushNotificationStorageLimit:100];
@endcode
*/
- (void)setPushNotificationStorageLimit:(long)limit;
@end
NS_ASSUME_NONNULL_END
