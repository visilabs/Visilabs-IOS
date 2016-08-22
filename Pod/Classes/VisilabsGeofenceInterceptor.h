//
//  VisilabsGeofenceInterceptor.h
//  Pods
//
//  Created by Visilabs on 15.08.2016.
//
//

#import <Foundation/Foundation.h>

@interface VisilabsGeofenceInterceptor : NSObject

/**
 Setup the first choice Responder.
 */
@property (nonatomic, weak) id firstResponder;

/**
 Setup the second choice Responder.
 */
@property (nonatomic, weak) id secondResponder;

@end
