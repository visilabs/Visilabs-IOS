//
//  VisilabsDataManager.h
//  Visilabs-IOS
//
//  Created by Visilabs on 7.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VisilabsDataManager : NSObject

+ (void)save:(NSString *)key withObject:(id)value;

+ (id)read:(NSString *)key;

+ (void)remove:(NSString *)key;

@end
