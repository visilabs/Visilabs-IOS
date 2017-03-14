//
//  EMTools.m
//  EuroPush
//
//  Created by Ozan Uysal on 20/04/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//

#import "EMTools.h"

@implementation EMTools


+ (BOOL) validatePhone:(NSString *) phone {
    if(phone) {
        return [phone length] > 9;
    }
    return false;
}

+ (BOOL) validateEmail:(NSString *) email {
    
    if(email) {
        
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        
        return [emailTest evaluateWithObject:email];
    }
    return false;
}

+ (id) retrieveUserDefaults:(NSString *) userKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:userKey] != nil)
        return [defaults objectForKey:userKey];
    else
        return nil;
}

+ (void) removeUserDefaults:(NSString *) userKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults objectForKey:userKey] != nil)
       [defaults removeObjectForKey:userKey];
}

+ (void) saveUserDefaults:(NSString *)key andValue:(id)value {
    if(key && value) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:value forKey:key];
        [defaults synchronize];
    }
}

+ (NSString *) getInfoString : (NSString *) key {
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSDictionary* infoDict = [bundle infoDictionary];
    return [infoDict objectForKey:key];
}

@end
