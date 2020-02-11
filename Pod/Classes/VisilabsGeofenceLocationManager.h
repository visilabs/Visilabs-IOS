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

@property (nonatomic, readonly) NSInteger bluetoothState;


@property (weak, nonatomic, readonly) NSArray *monitoredRegions;


@property (nonatomic, readonly) CLLocationDistance geofenceMaximumRadius;

@property (nonatomic) CLLocationCoordinate2D currentGeoLocationValue;


- (void)requestPermissionSinceiOS8 NS_AVAILABLE_IOS(8_0);


- (BOOL)startMonitorGeoLocationStandard:(BOOL)standard;


- (void)stopMonitorGeoLocation;


- (BOOL)startMonitorRegion:(CLRegion *)region;


- (void)stopMonitorRegion:(CLRegion *)region;

//TODO:added by egemen
@property(nonatomic, strong) NSMutableDictionary *geofenceDwellTimers;

@end
