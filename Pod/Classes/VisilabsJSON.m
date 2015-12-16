//
//  VisilabsJSON.m
//  Visilabs-IOS
//
//  Created by Visilabs on 7.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsJSON.h"

@implementation NSString (JSON)

- (id)objectFromJSONString {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data objectFromJSONData];
}

@end

@implementation NSData (JSON)

- (id)objectFromJSONData {
    return
    [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:nil];
}

/*egemen*/
//- (id)arrayFromJSONData {
//    return
//    [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:nil];
//}
/*egemen*/

@end

@implementation NSArray (JSON)

- (NSString *)JSONString {
    NSData *data = [self JSONData];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (NSData *)JSONData {
    return [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:nil];
}

@end

@implementation NSDictionary (JSON)

- (NSString *)JSONString {
    NSData *data = [self JSONData];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (NSData *)JSONData {
    return [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:nil];
}

@end
