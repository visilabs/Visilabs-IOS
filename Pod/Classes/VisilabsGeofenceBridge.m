//
//  VisilabsGeofenceBridge.m
//  Pods
//
//  Created by Visilabs on 16.08.2016.
//
//

#import "VisilabsGeofenceBridge.h"
#import "VisilabsGeofenceApp+Location.h"
#import "VisilabsGeofenceLocationManager.h"
#import "VisilabsGeofenceStatus.h"

@interface VisilabsGeofenceBridge ()

+ (void)createLocationManagerHandler:(NSNotification *)notification;
+ (void)setGeofenceTimestampHandler:(NSNotification *)notification;

@end

@implementation VisilabsGeofenceBridge

+ (void)bridgeHandler:(NSNotification *)notification
{    VisiGeofence.isDefaultLocationServiceEnabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createLocationManagerHandler:) name:@"SH_LMBridge_CreateLocationManager" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setGeofenceTimestampHandler:) name:@"SH_LMBridge_SetGeofenceTimestamp" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_SetGeofenceTimestamp" object:nil userInfo:@{@"timestamp": @"2016-01-01"}];
}

#pragma mark - private functions

+ (void)createLocationManagerHandler:(NSNotification *)notification
{
    if (VisiGeofence.locationManager == nil)
    {
        VisiGeofence.locationManager = [VisilabsGeofenceLocationManager sharedInstance];
    }
}

+ (void)setGeofenceTimestampHandler:(NSNotification *)notification
{    
    if(self.geofenceTimestampTimer != nil)
    {
        [self.geofenceTimestampTimer invalidate];

    }
    self.geofenceTimestampTimer = nil;
    self.geofenceTimestampTimer = [NSTimer scheduledTimerWithTimeInterval:900
                                                                   target:self
                                                                 selector:@selector(setHandler)
                                                                 userInfo:nil
                                                                  repeats:YES];
    
    [self.geofenceTimestampTimer fire];

}

+ (void)setHandler
{
    DLog(@"setHandler called");
    VisilabsGeofenceBridge.geofenceTimestampTimer = nil;
    [VisilabsGeofenceStatus sharedInstance].geofenceTimestamp = @"2016-01-01";
}

static NSTimer  *timer;

+ (NSTimer *)geofenceTimestampTimer {
    @synchronized(self)
    {
        return timer;
    }
}

+ (void) setGeofenceTimestampTimer:(NSTimer*)val
{
    @synchronized(self)
    {
        timer = val;
    }
}



@end
