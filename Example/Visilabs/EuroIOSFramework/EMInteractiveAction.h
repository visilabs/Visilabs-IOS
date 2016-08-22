//
//  EMInteractiveAction.h
//  EuroPush
//
//  Created by Ozan Uysal on 06/01/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMJSONModel.h"

@protocol EMInteractiveAction
@end

@interface EMInteractiveAction : EMJSONModel

@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) int activationMode;
@property (nonatomic, assign) bool destructive;
@property (nonatomic, assign) bool authenticationRequired;

@end
