//
//  VisilabsGeofenceApp+Location.m
//  Pods
//
//  Created by Visilabs on 15.08.2016.
//
//


#import "VisilabsGeofenceApp+Location.h"
#import "VisilabsGeofenceLocationManager.h"
#import <objc/runtime.h> //for associate object

NSString * const SHLMStartStandardMonitorNotification = @"SHLMStartStandardMonitorNotification";
NSString * const SHLMStopStandardMonitorNotification = @"SHLMStopStandardMonitorNotification";
NSString * const SHLMStartSignificantMonitorNotification = @"SHLMStartSignificantMonitorNotification";
NSString * const SHLMStopSignificantMonitorNotification = @"SHLMStopSignificantMonitorNotification";
NSString * const SHLMStartMonitorRegionNotification = @"SHLMStartMonitorRegionNotification";
NSString * const SHLMStopMonitorRegionNotification = @"SHLMStopMonitorRegionNotification";
NSString * const SHLMStartRangeiBeaconRegionNotification = @"SHLMStartRangeiBeaconRegionNotification";
NSString * const SHLMStopRangeiBeaconRegionNotification = @"SHLMStopRangeiBeaconRegionNotification";

NSString * const SHLMUpdateLocationSuccessNotification = @"SHLMUpdateLocationSuccessNotification";
NSString * const SHLMUpdateFailNotification = @"SHLMUpdateFailNotification";
NSString * const SHLMEnterRegionNotification = @"SHLMEnterRegionNotification";
NSString * const SHLMExitRegionNotification = @"SHLMExitRegionNotification";
NSString * const SHLMRegionStateChangeNotification = @"SHLMRegionStateChangeNotification";
NSString * const SHLMMonitorRegionSuccessNotification = @"SHLMMonitorRegionSuccessNotification";
NSString * const SHLMMonitorRegionFailNotification = @"SHLMMonitorRegionFailNotification";
NSString * const SHLMRangeiBeaconChangedNotification = @"SHLMRangeiBeaconChangedNotification";
NSString * const SHLMRangeiBeaconFailNotification = @"SHLMRangeiBeaconFailNotification";
NSString * const SHLMChangeAuthorizationStatusNotification = @"SHLMChangeAuthorizationStatusNotification";

NSString * const SHLMEnterExitGeofenceNotification = @"SHLMEnterExitGeofenceNotification";
NSString * const SHLMEnterExitBeaconNotification = @"SHLMEnterExitBeaconNotification";

NSString * const SHLMNotification_kNewLocation = @"NewLocation";
NSString * const SHLMNotification_kOldLocation = @"OldLocation";
NSString * const SHLMNotification_kError = @"Error";
NSString * const SHLMNotification_kRegion = @"Region";
NSString * const SHLMNotification_kRegionState = @"RegionState";
NSString * const SHLMNotification_kBeacons = @"Beacons";
NSString * const SHLMNotification_kAuthStatus = @"AuthStatus";

int const SHLocation_FG_Interval = 1;
int const SHLocation_FG_Distance = 100;
int const SHLocation_BG_Interval = 5;
int const SHLocation_BG_Distance = 500;

#define ENABLE_LOCATION_SERVICE             @"ENABLE_LOCATION_SERVICE"  //key for record user manually set isLocationServiceEnabled
#define REPORT_WORKHOME_LOCATION_ONLY       @"REPORT_WORKHOME_LOCATION_ONLY" //key for only report work home location

@implementation VisilabsGeofenceApp (LocationExt)

#pragma mark - properties

@dynamic isDefaultLocationServiceEnabled;
@dynamic isLocationServiceEnabled;
@dynamic locationManager;
@dynamic systemPreferenceDisableLocation;

- (BOOL)isDefaultLocationServiceEnabled
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(isDefaultLocationServiceEnabled));
    return [value boolValue];
}

- (void)setIsDefaultLocationServiceEnabled:(BOOL)isDefaultLocationServiceEnabled
{
    objc_setAssociatedObject(self, @selector(isDefaultLocationServiceEnabled), [NSNumber numberWithBool:isDefaultLocationServiceEnabled], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isLocationServiceEnabled
{
    //if never manually set isLocationServiceEnabled, use default value
    NSObject *setObj = [[NSUserDefaults standardUserDefaults] objectForKey:ENABLE_LOCATION_SERVICE];
    if (setObj == nil || ![setObj isKindOfClass:[NSNumber class]])
    {
        return self.isDefaultLocationServiceEnabled;
    }
    //otherwise use manually set value
    return [(NSNumber *)setObj boolValue];
}

- (void)setIsLocationServiceEnabled:(BOOL)isLocationServiceEnabled
{
    if (self.isLocationServiceEnabled != isLocationServiceEnabled)
    {
        if (isLocationServiceEnabled) 
        {
            //if enable update first, as next part will consider it.
            [[NSUserDefaults standardUserDefaults] setBool:isLocationServiceEnabled forKey:ENABLE_LOCATION_SERVICE];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [VisiGeofence.locationManager requestPermissionSinceiOS8];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_StartMonitorGeoLocation" object:nil];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_StopMonitorGeoLocation" object:nil];
            //if disable update after take effect, otherwise above function will ignore it.
            [[NSUserDefaults standardUserDefaults] setBool:isLocationServiceEnabled forKey:ENABLE_LOCATION_SERVICE];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        [VisiGeofence registerOrUpdateInstallWithHandler:nil]; //update "feature_locations"
    }
}

- (BOOL)reportWorkHomeLocationOnly
{
    NSObject *value = [[NSUserDefaults standardUserDefaults] objectForKey:REPORT_WORKHOME_LOCATION_ONLY];
    if (value != nil && [value isKindOfClass:[NSNumber class]])
    {
        return [(NSNumber *)value boolValue];
    }
    return NO;
}

- (void)setReportWorkHomeLocationOnly:(BOOL)reportWorkHomeLocationOnly
{
    [[NSUserDefaults standardUserDefaults] setBool:reportWorkHomeLocationOnly forKey:REPORT_WORKHOME_LOCATION_ONLY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_StartMonitorGeoLocation" object:nil];
}

- (VisilabsGeofenceLocationManager *)locationManager
{
    return objc_getAssociatedObject(self, @selector(locationManager));
}

- (void)setLocationManager:(VisilabsGeofenceLocationManager *)locationManager
{
    objc_setAssociatedObject(self, @selector(locationManager), locationManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)systemPreferenceDisableLocation
{
    BOOL globalDisable = ![CLLocationManager locationServicesEnabled];
    BOOL appDisable = [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied;
    return (globalDisable || appDisable);
}

- (void)setLocationUpdateFrequencyForFGInterval:(int)fgInterval forFGDistance:(int)fgDistance forBGInterval:(int)bgInterval forBGDistance:(int)bgDistance
{
    VisiGeofence.locationManager.fgMinTimeBetweenEvents = fgInterval;
    VisiGeofence.locationManager.fgMinDistanceBetweenEvents = fgDistance;
    VisiGeofence.locationManager.bgMinTimeBetweenEvents = bgInterval;
    VisiGeofence.locationManager.bgMinDistanceBetweenEvents = bgDistance;
}

@end
