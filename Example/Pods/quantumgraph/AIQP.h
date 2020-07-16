//
//  AIQP.h
//  QGSdk
//
//  Created by Ian.Lin on 2019/3/27.
//  Copyright © 2019 QGraph. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AIQP : NSObject

/*!
 @discussion
 Restrict external init calls and allow to use singleton.
 */
- (instancetype)init __attribute__((unavailable("Please use `+ (AIQP *)getContextForViewController:(UIViewController *)controller;` instead")));

/*!
 @abstract
 Get the AIQP instance with namespace for the specific UIViewController.

 @discussion
 This method should be called to in function @code viewWillAppear:animated: @endcode
 of the UIViewController. It will return the AIQP instance and which can be used to call
 its member functions. e.g.: @code getTextForKey:withDefaultValue: @endcode

 @note SDK Initialization, with onStart:withAppGroup:setDevProfile:, is necessary before AIQP can be used.

 @param controller         UIVewController
 */
+ (AIQP *)getContextForViewController:(UIViewController *)controller;

/*!
 @abstract
 Get the personalized value for text.
 
 @discussion
 This method will return the personalized value which is edited in the AIQUA
 Campaign on the Dashboard. If the value is not personalized, it will return
 the default value.
 
 @param key                 the key of the personalized text
 @param value               the default value of the key
 
 @result                    text value of the specific key
 */
- (NSString *)getTextForKey:(NSString *)key withDefaultValue:(NSString *)value;

/*!
 @abstract
 Get the personalized value for color.
 
 @discussion
 This method will return the personalized value which is edited in the AIQUA
 Campaign on the Dashboard. If the value is not personalized, it will return
 the default value.
 
 @param key                 the key of the personalized color
 @param value               the default hex color value of the key
 
 @result                    RGB hex of the specific key, e.g., @"ff0000" for red color.
 */
- (NSString *)getColorForKey:(NSString *)key withDefaultValue:(NSString *)value;


/*!
 @abstract
 Get UIColor from RGB hex String.
 
 @discussion
 This function converts RGB sex string to UIColor.
 
 @param string              RGB hex string, e.g., "ff0000"
 
 @result                    UIColor
 */
- (UIColor *)getUIColorFromRGBHexString:(NSString *)string;

/*!
 @abstract
 Get the personalized value for deeplink url string.
 
 @discussion
 This method will return the personalized value which is edited in the AIQUA
 Campaign on the Dashboard. If the value is not personalized, it will return
 the default value.
 
 @param key                 the key of the personalized deeplink
 @param value               the default URL string of the key, e.g.,
                            @"http://your.default.domain/index.htm"
 
 @result                    URL string of the specific key, e.g.,
                            @"http://your.personalized.domain/index.htm"
 */
- (NSString *)getDeepLinkForKey:(NSString *)key withDefaultValue:(NSString *)value;

/*!
 @abstract
 Get the personalized value for image url string
 
 @discussion
 This method will return the personalized value which is edited in the AIQUA
 Campaign on the Dashboard. If the value is not personalized, it will return
 the default value.
 
 @param key                 the key of the personalized image url
 @param value               the default image URL string of the key, e.g.,
                            @"http://your.default.domain/default.jpg"
 
 @result                    image URL string of the specific key, e.g.,
                            @"http://your.personalized.domain/personalized.jpg"
 */
- (NSString *)getImageUrlForKey:(NSString *)key withDefaultValue:(NSString *)value;


+ (void)setDisabledStatus:(BOOL)status;

@end
NS_ASSUME_NONNULL_END
