//
//  VisilabsTargetFilter.h
//  Pods
//
//  Created by Visilabs on 10.11.2016.
//
//

#import <Foundation/Foundation.h>


@interface VisilabsTargetFilter : NSObject


@property (nonatomic, strong) NSString *attribute;

@property (nonatomic, strong) NSString *filterType;

@property (nonatomic, strong) NSString *value;

@end


@interface VisilabsTargetFilterAbbreviated : NSObject

@property (nonatomic, strong) NSString *attr;

@property (nonatomic, strong) NSString *ft;

@property (nonatomic, strong) NSString *fv;

@end


@interface NSMutableArray (JSON)
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
