//
//  VisilabsGeofenceBridge.h
//  Pods
//
//  Created by Visilabs on 16.08.2016.
//
//

#import <Foundation/Foundation.h>

/**
 Bridge for handle geofence module notifications.
 */
@interface VisilabsGeofenceBridge : NSObject

/**
 Static entry point for bridge init.
 */
+ (void)bridgeHandler:(NSNotification *)notification;

+ (NSTimer *)geofenceTimestampTimer;
+ (void)setGeofenceTimestampTimer:(NSTimer *)timer;

@end
