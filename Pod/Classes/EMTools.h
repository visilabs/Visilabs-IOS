//
//  EMTools.h
//  EuroPush
//
//  Created by Ozan Uysal on 20/04/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMTools : NSObject

+ (BOOL) validatePhone:(NSString *) phone;
+ (BOOL) validateEmail:(NSString *) email;
+ (id) retrieveUserDefaults:(NSString *) userKey;
+ (void) removeUserDefaults:(NSString *) userKey;
+ (void) saveUserDefaults:(NSString *)key andValue:(id)value;
+ (NSString *) getInfoString : (NSString *) key;

@end
