//
//  EMSettingsModel.h
//  EuroPush
//
//  Created by Ozan Uysal on 06/01/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMInteractiveAction.h"
#import "NSArray+EMJSONModel.h"

@interface EMSettingsModel : EMJSONModel

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSArray<EMInteractiveAction> *actions;

@end
