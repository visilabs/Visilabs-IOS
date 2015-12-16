//
//  VisilabsJSON.h
//  Visilabs-IOS
//
//  Created by Visilabs on 7.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//


#import <Foundation/Foundation.h>

/**
 Extensions to standard primitive and collections classes to support easier json
 parsing. Internally, it uses the system provided 'NSJSONSerialization' class to perform
 the actual json serialization/deserialization
 */


/**
 JSON convenient categories on NSString
 */
@interface NSString (JSON)

/**
 Returns a Foundation object from the given JSON string.
 
 @return A Foundation object from the JSON string, or nil if an error occurs.
 */
- (id)objectFromJSONString;

@end

/**
 JSON convenient categories on NSData
 */
@interface NSData (JSON)

/**
 Returns a Foundation object from the given JSON data.
 
 @return A Foundation object from the JSON data, or nil if an error occurs.
 */
- (id)objectFromJSONData;

@end

/**
 JSON convenient categories on NSArray
 */
@interface NSArray (JSON)
/**
 Returns JSON string from the given array.
 
 @return a JSON String, or nil if an internal error occurs. The resulting data is
 a encoded in UTF-8.
 */
- (NSString *)JSONString;

/**
 Returns JSON data from the given array.
 
 @return a JSON data, or nil if an internal error occurs. The resulting data is a
 encoded in UTF-8.
 */
- (NSData *)JSONData;

@end

/**
 JSON convenient categories on NSDictionary
 */
@interface NSDictionary (JSON)

/**
 Returns JSON string from the given dictionary.
 
 @return a JSON String, or nil if an internal error occurs. The resulting data is
 a encoded in UTF-8.
 */
- (NSString *)JSONString;

/**
 Returns JSON data from the given dictionary.
 
 @return a JSON data, or nil if an internal error occurs. The resulting data is a
 encoded in UTF-8.
 */
- (NSData *)JSONData;

@end

