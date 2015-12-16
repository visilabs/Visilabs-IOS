//
//  VisilabsTargetRequest.h
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsAction.h"
#import "VisilabsConfig.h"

@interface VisilabsTargetRequest : VisilabsAction
    @property (nonatomic, strong) NSString *zoneID;
    @property (nonatomic, strong) NSString *productCode;
@end
