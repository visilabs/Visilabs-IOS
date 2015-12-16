//
//  VisilabsPersistentTargetManager.h
//  Visilabs-IOS
//
//  Created by Visilabs on 9.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsConfig.h"
#import "VisilabsParameter.h"
#import "VisilabsDataManager.h"

@interface VisilabsPersistentTargetManager : NSObject

+(void) saveParameters:(NSDictionary*) parameters;
+(NSDictionary*) getParameters;
+(void) clearParameters;
@end
