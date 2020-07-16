//
//  QGInbox.h
//  QGSdk
//
//  Created by Appier on 2019/7/16.
//  Copyright © 2019 QGraph. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, QGInboxLimit) {
    QGInboxLimitSmall     =  50,
    QGInboxLimitMedium    = 120,
    QGInboxLimitHigh      = 300,
    QGInboxLimitExtraHigh = 600
};

typedef NS_ENUM(NSInteger, QGInboxStatus) {
    QGInboxStatusUnread = 0,
    QGInboxStatusRead,
    QGInboxStatusDeleted
};

NS_ASSUME_NONNULL_BEGIN

@interface QGInbox : NSObject <NSCoding>

/*!
 @abstract
 An image url
 
 @discussion
 This is an image url related to the inbox message
 */
@property (nonatomic, readonly, copy) NSString * image;

/*!
 @abstract
 Title of the inbox message
 */
@property (nonatomic, readonly, copy) NSString * title;

/*!
 @abstract
 Message body of the inbox message
 */
@property (nonatomic, readonly, copy) NSString * text;

/*!
 @abstract
 Custom deeplink url
 */
@property (nonatomic, readonly, copy) NSString * deepLink;

/*!
 @abstract
 Custom parameters(Key, Value) for the inbox message
 */
@property (nonatomic, readonly, copy) NSDictionary * qgPayload;

/*!
 @abstract
 Unique id of the inbox message
 */
@property (nonatomic, readonly, copy) NSNumber * notificationId;

/*!
 @abstract
 Expiration time of the inbox message. If current time exceed it, the inbox message should be removed
 */
@property (nonatomic, readonly) long long endTime;

/*!
 @abstract
 Starting time for the inbox message. It is supposed to be smaller than endTime
 */
@property (nonatomic, readonly) long long startTime;

/*!
 @abstract
 It is a mark or flag for the inbox message. Ex: Unread (Default), Read, Deleted
 */
@property (nonatomic, readonly) QGInboxStatus status;

/*!
 @abstract
 Update current status with new one. The method looks more formal rather than just use dot operation to change the value
 
 @discussion
 This methods will also save the new status back to userDefault
 
 @param newStatus new QGInboxStatus
 
 @code
 NSArray <QGInbox *> *listInbox = [[QGSdk getSharedInstance] getInboxesWithStatusRead:NO statusUnread:NO statusDeleted:YES];
 QGInbox * first = [listinbox objectAtIndex:0];
 [first updateStatus:QGInboxStatusDeleted]; // Save status as Deleted
 [first updateStatus:QGInboxStatusRead];    // Save status as Read
 @endcode
 */
- (void)updateStatus:(QGInboxStatus)newStatus;

/*!
 @abstract
 Track any event for one inbox message with custom parameters and monetary value associated to it along with its currency
 
 @discussion
 Combination of logEvent:withParameter and logEvent:withValueToSum:withValueToSumCurrency

 @param name            name of the event
 @param parameters      dictionary of all the parameter for the event
 @param valueToSum      monetary value (NSNumber) associated to the event
 @param vtsCurr         currency code of the value to sum
 
 @code
 NSArray <QGInbox *> *listInbox = [[QGSdk getSharedInstance] getInboxesWithStatusRead:NO statusUnread:NO statusDeleted:YES];
 QGInbox * first = [listinbox objectAtIndex:0];
 [first logEvent:@"first_log" withParameters:@{@"key":@"value"} withValueToSum:nil withValueToSumCurrency:nil];
 @endcode
 */
- (void)logEvent:(NSString *)name withParameters:(nullable NSDictionary *)parameters withValueToSum:(nullable NSNumber *) valueToSum withValueToSumCurrency:(nullable NSString *)vtsCurr;
@end

NS_ASSUME_NONNULL_END
