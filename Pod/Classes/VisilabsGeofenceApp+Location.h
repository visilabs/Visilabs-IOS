//
//  VisilabsGeofenceApp+Location.h
//  Pods
//
//  Created by Visilabs on 15.08.2016.
//
//

#import "VisilabsGeofenceApp.h" //for extension SHApp


extern NSString * const SHLMStartStandardMonitorNotification;

extern NSString * const SHLMStopStandardMonitorNotification;

extern NSString * const SHLMStartSignificantMonitorNotification;

extern NSString * const SHLMStopSignificantMonitorNotification;

extern NSString * const SHLMStartMonitorRegionNotification;

extern NSString * const SHLMStopMonitorRegionNotification;

extern NSString * const SHLMUpdateLocationSuccessNotification;

extern NSString * const SHLMUpdateFailNotification;

extern NSString * const SHLMEnterRegionNotification;

extern NSString * const SHLMExitRegionNotification;

extern NSString * const SHLMRegionStateChangeNotification;

extern NSString * const SHLMMonitorRegionSuccessNotification;

extern NSString * const SHLMMonitorRegionFailNotification;

extern NSString * const SHLMChangeAuthorizationStatusNotification;

extern NSString * const SHLMEnterExitGeofenceNotification;

extern NSString * const SHLMNotification_kNewLocation; //string @"NewLocation", get CLLocation.
extern NSString * const SHLMNotification_kOldLocation; //string @"OldLocation", get CLLocation.
extern NSString * const SHLMNotification_kError; //string @"Error", get NSError.
extern NSString * const SHLMNotification_kRegion; //string @"Region", get CLRegion.
extern NSString * const SHLMNotification_kRegionState; //string @"RegionState", get CLRegionState enum.
extern NSString * const SHLMNotification_kAuthStatus;  //string @"AuthStatus", get NSNumber for int representing CLAuthorizationStatus.

extern int const SHLocation_FG_Interval; //Default minimum time interval for updating location when App in FG, 1 mins.
extern int const SHLocation_FG_Distance; //Default minimum distance for updating location when App in FG, 100 meters.
extern int const SHLocation_BG_Interval; //Default minimum time interval for updating location when App in BG, 5 mins.
extern int const SHLocation_BG_Distance; //Default minimum distance for updating location when App in BG, 500 meters.

@class VisilabsGeofenceLocationManager;


@interface VisilabsGeofenceApp (LocationExt)


@property (nonatomic) BOOL isDefaultLocationServiceEnabled;


@property (nonatomic) BOOL isLocationServiceEnabled;


@property (nonatomic) BOOL reportWorkHomeLocationOnly;


@property (nonatomic, strong) VisilabsGeofenceLocationManager *locationManager;


@property (nonatomic, readonly) BOOL systemPreferenceDisableLocation;


- (void)setLocationUpdateFrequencyForFGInterval:(int)fgInterval forFGDistance:(int)fgDistance forBGInterval:(int)bgInterval forBGDistance:(int)bgDistance;

@end
