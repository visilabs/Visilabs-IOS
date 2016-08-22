//
//  BaseObject.m
//  PigeoniOSSDK
//
//  Created by Ozan Uysal on 25/10/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "objc/runtime.h"

#import "BaseObject.h"

@implementation BaseObject

NSString* getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T') {
            return [[NSString alloc] initWithBytes:attribute + 3 length:strlen(attribute) - 4 encoding:NSASCIIStringEncoding];
        }
    }
    return @"@";
}


- (NSMutableDictionary *)getDictionary
{
    Class klass = self.class;
    if (klass == NULL) {
        return nil;
    }
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    
    NSMutableDictionary * results = [NSMutableDictionary dictionaryWithCapacity:outCount];
    
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            
            NSString * value = [self valueForKey:propertyName];
            if (value) {
                [results setObject:value forKey:propertyName];
            }
        }
    }
    free(properties);
    
    return results;
}

@end