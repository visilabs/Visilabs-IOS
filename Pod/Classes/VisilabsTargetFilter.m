//
//  VisilabsWidgetFilter.m
//  Pods
//
//  Created by Visilabs on 10.11.2016.
//
//

#import "VisilabsTargetFilter.h"

@implementation VisilabsTargetFilter

@end




@implementation VisilabsTargetFilterAbbreviated

@end



@implementation NSMutableArray (JSON)

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
