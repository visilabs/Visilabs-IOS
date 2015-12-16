//
//  VisilabsParameter.m
//  Visilabs-IOS
//
//  Created by Visilabs on 7.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsParameter.h"


@implementation VisilabsParameter
- (instancetype)initWithKey:(NSString *)key
                   storeKey:(NSString *)storeKey
                      count:(NSNumber *)count
                relatedKeys:(NSArray *)relatedKeys
{
    if (self = [super init]) {
        _relatedKeys = [[NSArray alloc] init];
        if(relatedKeys)
        {
            _relatedKeys = relatedKeys;
        }
        _key = key;
        _storeKey = storeKey;
        _count = count;
    }
    return self;
}
@end
