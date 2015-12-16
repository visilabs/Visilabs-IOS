//
//  VisilabsParameter.h
//  Visilabs-IOS
//
//  Created by Visilabs on 7.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface VisilabsParameter : NSObject
    @property (nonatomic, retain) NSString * key;
    @property (nonatomic, retain) NSString * storeKey;
    @property (nonatomic, retain) NSNumber * count;
    @property (nonatomic, retain) NSArray * relatedKeys;
    - (instancetype)initWithKey:(NSString *)key
                     storeKey:(NSString *)storeKey
                     count:(NSNumber *)count
                     relatedKeys:(NSArray *)relatedKeys;
@end
