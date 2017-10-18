//
//  VisilabsGeofenceLocationManager.h
//  Pods
//
//  Created by Visilabs on 15.08.2016.
//
//

#import "VisilabsGeofenceApp+Location.h"
#import <CoreLocation/CoreLocation.h>

/**
 The state of current geolocation update.
 */
enum SHGeoLocationMonitorState
{
    /**
     Not monitor geolocation.
     */
    SHGeoLocationMonitorState_Stopped,
    /**
     Monitor geolocation in standard way, called by `startUpdatingLocation`.
     */
    SHGeoLocationMonitorState_MonitorStandard,
    /**
     Monitor geolocation in significant change way, called by `startMonitoringSignificantLocationChanges`.
     */
    SHGeoLocationMonitorState_MonitorSignificant,
};
typedef enum SHGeoLocationMonitorState SHGeoLocationMonitorState;

/**
 The status of current device's iBeacon support.
 */
enum SHiBeaconState
{
    /**
     Bluetooth state not determined yet, unknown at this moment.
     */
    SHiBeaconState_Unknown = 0,
    /**
     Current device is ready to use iBeacon, means it's iOS 7.0+, location service enabled, Bluetooth on.
     */
    SHiBeaconState_Support = 1,
    /**
     Current device not ready to use iBeacon, one condition not match.
     */
    SHiBeaconState_NotSupport = 2,
    /**
     Not have Beacon module, ignore this statue.
     */
    SHiBeaconState_Ignore = 3,
};
typedef enum SHiBeaconState SHiBeaconState;


@interface VisilabsGeofenceLocationManager : NSObject<CLLocationManagerDelegate>


+ (VisilabsGeofenceLocationManager *)sharedInstance;


+ (BOOL)locationServiceEnabledForApp:(BOOL)allowNotDetermined;


@property (nonatomic, readonly) SHGeoLocationMonitorState geolocationMonitorState;


@property (nonatomic, readonly) CLLocationCoordinate2D currentGeoLocation;


@property (nonatomic) CLLocationAccuracy desiredAccuracy;


@property (nonatomic) CLLocationDistance distanceFilter;

@property (nonatomic) NSTimeInterval fgMinTimeBetweenEvents;


@property (nonatomic) NSTimeInterval bgMinTimeBetweenEvents;


@property (nonatomic) float fgMinDistanceBetweenEvents;


@property (nonatomic) float bgMinDistanceBetweenEvents;


@property (nonatomic, readonly) SHiBeaconState iBeaconSupportState;


@property (nonatomic, readonly) NSInteger bluetoothState;


@property (weak, nonatomic, readonly) NSArray *monitoredRegions;


@property (nonatomic, readonly) CLLocationDistance geofenceMaximumRadius;

@property (nonatomic) CLLocationCoordinate2D currentGeoLocationValue;


- (void)requestPermissionSinceiOS8 NS_AVAILABLE_IOS(8_0);


- (BOOL)startMonitorGeoLocationStandard:(BOOL)standard;


- (void)stopMonitorGeoLocation;


- (BOOL)startMonitorRegion:(CLRegion *)region;


- (void)stopMonitorRegion:(CLRegion *)region;


- (BOOL)startRangeiBeaconRegion:(CLBeaconRegion *)iBeaconRegion __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);


- (void)stopRangeiBeaconRegion:(CLBeaconRegion *)iBeaconRegion __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);

//TODO:added by egemen
@property(nonatomic, strong) NSMutableDictionary *geofenceDwellTimers;

@end
