//
//  VisilabsTargetRequest.h
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsAction.h"
#import "VisilabsConfig.h"
#import "VisilabsTargetFilter.h"

enum VisilabsTargetRequestType
{
    VisilabsTargetRequestTypeRecommendation,
    VisilabsTargetRequestTypeFavorite
};
typedef enum VisilabsTargetRequestType VisilabsTargetRequestType;

@interface VisilabsTargetRequest : VisilabsAction
    @property (nonatomic) VisilabsTargetRequestType targetRequestType;
    @property (nonatomic, strong) NSString *actionID;
    @property (nonatomic, strong) NSString *zoneID;
    @property (nonatomic, strong) NSString *productCode;
    @property (nonatomic, strong) NSMutableDictionary *properties;
    @property (nonatomic, strong) NSMutableArray<VisilabsTargetFilter *> *filters;
@end
