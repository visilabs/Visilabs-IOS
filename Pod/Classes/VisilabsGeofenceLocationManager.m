//
//  VisilabsGeofenceLocationManager.m
//  Pods
//
//  Created by Visilabs on 15.08.2016.
//
//


#import "VisilabsDefines.h"
#import "VisilabsGeofenceLocationManager.h"
#import "VisilabsGeofenceApp.h" 
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "VisilabsReachability.h"
#import "VisilabsGeofenceStatus.h"
#import "VisilabsGeofenceRequest.h"
#import "Visilabs.h"
#import <MapKit/MapKit.h>


#define LOCATION_DENIED_SENT        @"LOCATION_DENIED_SENT" //a flag indicates this App has sent location denied log to avoid send one more time.
#define NETWORK_RECOVER_TIME        @"NETWORK_RECOVER_TIME" //Record time when network from not-connected to connected(either cellura or Wifi). If it's 0 means current network not connected; if it's number means last time from non-connected to connected.

#define SH_FG_INTERVAL  @"SH_FG_INTERVAL" //value for location update time interval in FG
#define SH_FG_DISTANCE  @"SH_FG_DISTANCE" //value for location update distance in FG
#define SH_BG_INTERVAL  @"SH_BG_INTERVAL" //value for location update time interval in BG
#define SH_BG_DISTANCE  @"SH_BG_DISTANCE" //value for location update distance in BG

@interface VisilabsGeofenceLocationManager()

@property (nonatomic, strong) CLLocationManager *locationManager;  //The internal operating iOS object.
//@property (nonatomic) CLLocationCoordinate2D currentGeoLocationValue; //extent read-write access
@property (nonatomic) CLLocationCoordinate2D sentGeoLocationValue; //sent by log location 20
@property (nonatomic) NSTimeInterval sentGeoLocationTime;  //for calculate time delta to prevent too often location update notification send.

- (void)createLocationManager;  //create internal operating iOS object.
- (double)distanceSquaredForLat1:(double)lat1 lng1:(double)lng1 lat2:(double)lat2 lng2:(double)lng2; //Calculates the square of distance between two lat/longs. Geared for speed over accuracy.
- (void)sendGeoLocationUpdate;

- (NSString *)formatBeaconRegion:(CLBeaconRegion *)region;  //format beacon region to a string in format UUID-major-minor-identifier.
- (BOOL)isRegionSame:(CLRegion *)r1 with:(CLRegion *)r2;  //compare two iBeacon region is same.

@property (nonatomic, strong) CBCentralManager *bluetoothManager; //report bluetooth status to detech iBeacon, only initialized for iOS 7.0 above.
- (void)createBluetoothManager;

@property (nonatomic, strong) VisilabsReachability *reachability;
- (void)createNetworkMonitor; //create Reachability to monitor network status change.
- (void)networkStatusChanged:(NSNotification *)notification; //handle for notification for network status change.
- (BOOL)updateRecoverTime; //update NETWORK_RECOVER_TIME value. Return YES if connect and non-connect change.



@end

@implementation VisilabsGeofenceLocationManager

#pragma mark - life cycle

+ (void)initialize
{
    if ([self class] == [VisilabsGeofenceLocationManager class])
    {
        NSMutableDictionary *initialDefaults = [NSMutableDictionary dictionary];
        initialDefaults[SH_FG_INTERVAL] = @(SHLocation_FG_Interval);
        initialDefaults[SH_FG_DISTANCE] = @(SHLocation_FG_Distance);
        initialDefaults[SH_BG_INTERVAL] = @(SHLocation_BG_Interval);
        initialDefaults[SH_BG_DISTANCE] = @(SHLocation_BG_Distance);
        [[NSUserDefaults standardUserDefaults] registerDefaults:initialDefaults];
    }
}

+ (VisilabsGeofenceLocationManager *)sharedInstance
{
    static VisilabsGeofenceLocationManager *sharedLocationManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocationManager = [[VisilabsGeofenceLocationManager alloc] init];
    });
    return sharedLocationManager;
}

- (id)init
{
    if ((self = [super init]))
    {
        [self createLocationManager];
        [self createBluetoothManager];
        [self createNetworkMonitor];
    }
    return self;
}

- (void)createLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
#if !TARGET_IPHONE_SIMULATOR //pausesLocationUpdatesAutomatically cannot work in non-UI clients such as unit testing. As unit testing only run in simulator, add macro to avoid crash.
    if ([self.locationManager respondsToSelector:@selector(setPausesLocationUpdatesAutomatically:)])
    {
        self.locationManager.pausesLocationUpdatesAutomatically = NO;  //since iOS 6.0, if error happen whether pause location update to save battery? Set to NO so that retrying and keeping report.
    }
#endif
    [self requestPermissionSinceiOS8];
    
    self.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.distanceFilter = 10.0f;
    
    //initialize detecting location
    self.currentGeoLocationValue = CLLocationCoordinate2DMake(0, 0);
    
    self.sentGeoLocationValue = CLLocationCoordinate2DMake(0, 0);
    self.sentGeoLocationTime = 0;  //not update yet
    _geolocationMonitorState = SHGeoLocationMonitorState_Stopped;
    

    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_StartMonitorGeoLocation" object:nil];
    
    
    //bunu sonradan ekledim.
    if ([CLLocationManager significantLocationChangeMonitoringAvailable])
    {
        DLog(@"LocationManager Action: Start significant location update.");
        [self.locationManager startMonitoringSignificantLocationChanges];
        _geolocationMonitorState = SHGeoLocationMonitorState_MonitorSignificant;
        //[[NSNotificationCenter defaultCenter] postNotificationName:SHLMStartSignificantMonitorNotification object:self];
    }
    

}

- (void)createBluetoothManager
{
    if ([CBCentralManager instancesRespondToSelector:@selector(initWithDelegate:queue:options:)])  //`options` since iOS 7.0, must have this to depress system dialog
    {
        self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: @(0)}];
    }
}

- (void)createNetworkMonitor
{
    self.reachability = [VisilabsReachability reachabilityForInternetConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kReachabilityChangedNotification object:nil];
    [self.reachability startNotifier];
    [self updateRecoverTime]; //notifier not trigger when start, update to correct value in initalize.
}

- (void)dealloc
{
    self.locationManager.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.reachability stopNotifier];
}

#pragma mark - check system setup app's enable

+ (BOOL)locationServiceEnabledForApp:(BOOL)allowNotDetermined
{
    //Since iOS 8 must add key in Info.plist otherwise location service won't start.
    if ([[UIDevice currentDevice].systemVersion doubleValue] >= 8.0)
    {
        NSString *locationAlwaysStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"];
        NSString *locationWhileInUseStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"];
        if (locationAlwaysStr == nil && locationWhileInUseStr == nil) //cannot check length != 0 because Info.plist can add empty string for these key and location is enabled.
        {
            return NO;  //this iOS 8 App not configure location service key, it's not enabled. cannot avoid this check as it's [CLLocationManager authorizationStatus] is kCLAuthorizationStatusNotDetermined.
        }
    }
    if (!VisiGeofence.isLocationServiceEnabled/*code allow*/ || ![CLLocationManager locationServicesEnabled]/**Global location service is enabled.*/)
    {
        return NO;
    }
    BOOL isEnabled;
    if (allowNotDetermined)
    {
        isEnabled = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized /*Individual App location service is enabled.*/
                     || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways /*Sinc iOS 8, equal to kCLAuthorizationStatusAuthorized*/
                     || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse /*Since iOS 8, */
                     || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined/*Need this also, otherwise not ask for permission at first launch.*/);
    }
    else
    {
        isEnabled = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized /*Individual App location service is enabled.*/
                     || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways /*Sinc iOS 8, equal to kCLAuthorizationStatusAuthorized*/
                     || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse /*Since iOS 8, */);
    }
    if (isEnabled)
    {
        NSString *sentFlag = [[NSUserDefaults standardUserDefaults] objectForKey:LOCATION_DENIED_SENT];
        if (sentFlag != nil && sentFlag.length > 0)
        {
            //clear location denied flag
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:LOCATION_DENIED_SENT];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    return isEnabled;
}

#pragma mark - visit geo location detective result

- (CLLocationCoordinate2D)currentGeoLocation
{
    if ([VisilabsGeofenceLocationManager locationServiceEnabledForApp:NO])  //If location service disabled, this local value is meaningless.
    {
        return self.currentGeoLocationValue;
    }
    else
    {
        return CLLocationCoordinate2DMake(0, 0);
    }
}

#pragma mark - set geo location service properties

- (CLLocationAccuracy)desiredAccuracy
{
    return self.locationManager.desiredAccuracy;
}

- (void)setDesiredAccuracy:(CLLocationAccuracy)accuracy
{
    self.locationManager.desiredAccuracy = accuracy;
}

- (CLLocationDistance)distanceFilter
{
    return self.locationManager.distanceFilter;
}

- (void)setDistanceFilter:(CLLocationDistance)distance
{
    self.locationManager.distanceFilter = distance;
}

- (NSTimeInterval)fgMinTimeBetweenEvents
{
    NSTimeInterval value = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_FG_INTERVAL] doubleValue];
    NSAssert(value >= 0, @"Not find suitable value for SH_FG_INTERVAL");
    if (value >= 0)
    {
        return value;
    }
    else
    {
        return SHLocation_FG_Interval;
    }
}

- (void)setFgMinTimeBetweenEvents:(NSTimeInterval)fgMinTimeBetweenEvents
{
    if (fgMinTimeBetweenEvents >= 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@(fgMinTimeBetweenEvents) forKey:SH_FG_INTERVAL];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (float)fgMinDistanceBetweenEvents
{
    float value = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_FG_DISTANCE] floatValue];
    NSAssert(value >= 0, @"Not find suitable value for SH_FG_DISTANCE");
    if (value >= 0)
    {
        return value;
    }
    else
    {
        return SHLocation_FG_Distance;
    }
}

- (void)setFgMinDistanceBetweenEvents:(float)fgMinDistanceBetweenEvents
{
    if (fgMinDistanceBetweenEvents >= 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@(fgMinDistanceBetweenEvents) forKey:SH_FG_DISTANCE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSTimeInterval)bgMinTimeBetweenEvents
{
    NSTimeInterval value = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_BG_INTERVAL] doubleValue];
    NSAssert(value >= 0, @"Not find suitable value for SH_BG_INTERVAL");
    if (value >= 0)
    {
        return value;
    }
    else
    {
        return SHLocation_BG_Interval;
    }
}

- (void)setBgMinTimeBetweenEvents:(NSTimeInterval)bgMinTimeBetweenEvents
{
    if (bgMinTimeBetweenEvents >= 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@(bgMinTimeBetweenEvents) forKey:SH_BG_INTERVAL];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (float)bgMinDistanceBetweenEvents
{
    float value = [[[NSUserDefaults standardUserDefaults] objectForKey:SH_BG_DISTANCE] doubleValue];
    NSAssert(value >= 0, @"Not find suitable value for SH_BG_DISTANCE");
    if (value >= 0)
    {
        return value;
    }
    else
    {
        return SHLocation_BG_Distance;
    }
}

- (void)setBgMinDistanceBetweenEvents:(float)bgMinDistanceBetweenEvents
{
    if (bgMinDistanceBetweenEvents >= 0)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@(bgMinDistanceBetweenEvents) forKey:SH_BG_DISTANCE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - detecting result

- (SHiBeaconState)iBeaconSupportState
{
    if ([CLLocationManager respondsToSelector:@selector(isRangingAvailable)]) //since iOS 7.0
    {
        if ([VisilabsGeofenceLocationManager locationServiceEnabledForApp:NO] && [CLLocationManager isRangingAvailable] && [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]])
        {
            if (self.bluetoothState == CBCentralManagerStatePoweredOn)  //bluetooth is turn on and ready for use
            {
                return SHiBeaconState_Support;
            }
            else if (self.bluetoothState == CBCentralManagerStateUnknown)  //bluetooth state is not determined yet, need to wait some time.
            {
                return SHiBeaconState_Unknown;
            }
        }
    }
    return SHiBeaconState_NotSupport;
}

- (NSInteger)bluetoothState
{
    return self.bluetoothManager.state;  //if not 7.0 self.bluetoothManager=nil because it's not alloc, return 0 as unknown.
}

- (NSArray *)monitoredRegions
{
    return self.locationManager.monitoredRegions.allObjects;
}

- (CLLocationDistance)geofenceMaximumRadius
{
    return self.locationManager.maximumRegionMonitoringDistance;
}

#pragma mark - operation

- (void)requestPermissionSinceiOS8
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    BOOL enabled = VisiGeofence.isLocationServiceEnabled;
    
    if (enabled && status == kCLAuthorizationStatusNotDetermined)
    {
        NSString *locationAlwaysStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"];
        if (locationAlwaysStr != nil) //if customer added "Always" uses this permission, recommended. cannot check length != 0 because Info.plist can add empty string for these key and location is enabled.
        {
            if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
            {
                [self.locationManager requestAlwaysAuthorization]; //since iOS 8.0, must request for one authorization type, meanwhile, customer App must add `NSLocationAlwaysUsageDescription` in Info.plist.
            }
        }
        else
        {
            NSString *locationWhileInUseStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"];
            if (locationWhileInUseStr != nil)
            {
                if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
                {
                    [self.locationManager requestWhenInUseAuthorization]; //since iOS 8.0, if Always not available, try WhenInUse as secondary option.
                }
            }
        }
    }
}

- (BOOL)startMonitorGeoLocationStandard:(BOOL)standard
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return NO;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    [self requestPermissionSinceiOS8]; //request before action, it simply return if not suitable.
    if (self.geolocationMonitorState == SHGeoLocationMonitorState_Stopped
        || (standard && self.geolocationMonitorState == SHGeoLocationMonitorState_MonitorSignificant)
        || (!standard && self.geolocationMonitorState == SHGeoLocationMonitorState_MonitorStandard))  //avoid stop and start for the same mode
    {
        if ([VisilabsGeofenceLocationManager locationServiceEnabledForApp:YES/*for first time promote permission dialog*/])
        {
            //as the mode change, need to stop and start in new mode again
            [self stopMonitorGeoLocation];
            if (standard)
            {
                //start standard services
                DLog(@"LocationManager Action: Start standard location update.");
                [self.locationManager startUpdatingLocation];
                _geolocationMonitorState = SHGeoLocationMonitorState_MonitorStandard;
                [[NSNotificationCenter defaultCenter] postNotificationName:SHLMStartStandardMonitorNotification object:self];
            }
            else
            {
                //This check `significantLocationChangeMonitoringAvailable` always return YES in testing so it actually does not affect current logic. Add this code be more complete.
                //It returns YES for testing in simulator new and old (6.1), returns YES for iPad 3 Wifi (although a stackoverflow says iPad 1 Wifi not support, but not have device on hand).
                //Another stackoverflow says this API is added on iOS 4 but really support it since iOS 5. http://stackoverflow.com/questions/11609809/significantlocationchangemonitoringavailable-not-working-on-ios-4
                if ([CLLocationManager significantLocationChangeMonitoringAvailable])
                {
                    DLog(@"LocationManager Action: Start significant location update.");
                    [self.locationManager startMonitoringSignificantLocationChanges];
                    _geolocationMonitorState = SHGeoLocationMonitorState_MonitorSignificant;
                    [[NSNotificationCenter defaultCenter] postNotificationName:SHLMStartSignificantMonitorNotification object:self];
                }
                else
                {
                    [self locationManager:self.locationManager didFailWithError:[NSError errorWithDomain:SHErrorDomain code:kCLErrorDenied userInfo:@{NSLocalizedDescriptionKey: @"Significant location change not available."}]];
                    return NO;
                }
            }
        }
        else
        {
            [self locationManager:self.locationManager didFailWithError:[NSError errorWithDomain:SHErrorDomain code:kCLErrorDenied userInfo:@{NSLocalizedDescriptionKey: @"Location service denied by user."}]];
            return NO;
        }
    }
    return YES;
}

- (void)stopMonitorGeoLocation
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    if (self.geolocationMonitorState != SHGeoLocationMonitorState_Stopped)
    {
        if (self.geolocationMonitorState == SHGeoLocationMonitorState_MonitorStandard)
        {
            DLog(@"LocationManager Action: Stop standard location update.");
            [self.locationManager stopUpdatingLocation];
            _geolocationMonitorState = SHGeoLocationMonitorState_Stopped;
            [[NSNotificationCenter defaultCenter] postNotificationName:SHLMStopStandardMonitorNotification object:self];
        }
        if (self.geolocationMonitorState == SHGeoLocationMonitorState_MonitorSignificant)
        {
            DLog(@"LocationManager Action: Stop significant location update.");
            [self.locationManager stopMonitoringSignificantLocationChanges];
            _geolocationMonitorState = SHGeoLocationMonitorState_Stopped;
            [[NSNotificationCenter defaultCenter] postNotificationName:SHLMStopSignificantMonitorNotification object:self];
        }
    }
}

- (BOOL)startMonitorRegion:(CLRegion *)region
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return NO;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    [self requestPermissionSinceiOS8]; //request before action, it simply return if not suitable.
    BOOL isMonitorRegionAvailable = [VisilabsGeofenceLocationManager locationServiceEnabledForApp:NO];
    if (isMonitorRegionAvailable)
    {
        if ([CLLocationManager respondsToSelector:@selector(isMonitoringAvailableForClass:)]) //since iOS 7.0
        {
            isMonitorRegionAvailable = [CLLocationManager isMonitoringAvailableForClass:region.class];
        }
        else
        {
            isMonitorRegionAvailable = NO;//[CLLocationManager regionMonitoringAvailable];
        }
    }
    if (!isMonitorRegionAvailable)
    {
        [self locationManager:self.locationManager didFailWithError:[NSError errorWithDomain:SHErrorDomain code:kCLErrorDenied userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Device not capable to monitor region: %@.", region]}]];
        return NO;
    }
    //check whether this region is already monitored. if same region is monitored ignore this call; if not same region but with same identifier is monitored, print warning.
    __block CLRegion *sameIdRegion = nil;
    [self.locationManager.monitoredRegions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        CLRegion *monitoredRegion = (CLRegion *)obj;
        if ([monitoredRegion.identifier compare:region.identifier options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            sameIdRegion = monitoredRegion; //find one already monitored with same identifier
            *stop = YES;
        }
    }];
    if (sameIdRegion != nil)
    {
        if ([self isRegionSame:sameIdRegion with:region])  //same uuid, max, major region monitored, ignore this action, no need to add again.
        {
            return NO;
        }
        else
        {
            DLog(@"Warning: same identifier region %@ monitored. Add new %@ will remove the already monitored one.", sameIdRegion, region);
        }
    }
    DLog(@"LocationManager Action: Start monitor region %@.", region);
    [self.locationManager startMonitoringForRegion:region];
    NSDictionary *userInfo = @{SHLMNotification_kRegion: region};
    NSNotification *notification = [NSNotification notificationWithName:SHLMStartMonitorRegionNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    return YES;
}

- (void)stopMonitorRegion:(CLRegion *)region
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    __block BOOL isFound = NO;
    [self.locationManager.monitoredRegions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        CLRegion *monitoredRegion = (CLRegion *)obj;
        if ([self isRegionSame:monitoredRegion with:region])
        {
            isFound = YES;
            *stop = YES;
        }
    }];
    if (isFound)
    {
        DLog(@"LocationManager Action: Stop monitor region %@.", region);
        [self.locationManager stopMonitoringForRegion:region];
        NSDictionary *userInfo = @{SHLMNotification_kRegion: region};
        NSNotification *notification = [NSNotification notificationWithName:SHLMStopMonitorRegionNotification object:self userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (BOOL)startRangeiBeaconRegion:(CLBeaconRegion *)iBeaconRegion
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return NO;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    if (self.iBeaconSupportState == SHiBeaconState_NotSupport) //if support contine; if unknown that's caused by bluetooth, continue; if not support, means iOS version less than 7, stop to avoid crash.
    {
        return NO;
    }
    [self requestPermissionSinceiOS8]; //request before action, it simply return if not suitable.
    __block BOOL isFound = NO;
    [self.locationManager.rangedRegions enumerateObjectsUsingBlock:^(id obj, BOOL *stop)
     {
         CLBeaconRegion *rangedRegion = (CLBeaconRegion *)obj;
         if ([self isRegionSame:rangedRegion with:iBeaconRegion]) //CLBeaconRegion isEqual is not correct, for example, after I change UUID it still return equal. So compare beacon region manually.
         {
             isFound = YES;
             *stop = YES;
         }
     }];
    if (!isFound)
    {
        DLog(@"LocationManager Action: Start range region %@.", iBeaconRegion);
        [self.locationManager startRangingBeaconsInRegion:iBeaconRegion];
        NSDictionary *userInfo = @{SHLMNotification_kRegion: iBeaconRegion};
        [[NSNotificationCenter defaultCenter] postNotificationName:SHLMStartRangeiBeaconRegionNotification object:self userInfo:userInfo];
    }
    return !isFound;
}

- (void)stopRangeiBeaconRegion:(CLBeaconRegion *)iBeaconRegion
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    __block BOOL isFound = NO;
    [self.locationManager.rangedRegions enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        CLRegion *rangedRegion = (CLBeaconRegion *)obj;
        if ([self isRegionSame:rangedRegion with:iBeaconRegion])
        {
            isFound = YES;
            *stop = YES;
        }
    }];
    if (isFound)
    {
        DLog(@"LocationManager Action: Stop range region %@.", iBeaconRegion);
        [self.locationManager stopRangingBeaconsInRegion:iBeaconRegion];
        NSDictionary *userInfo = @{SHLMNotification_kRegion: iBeaconRegion};
        [[NSNotificationCenter defaultCenter] postNotificationName:SHLMStopRangeiBeaconRegionNotification object:self userInfo:userInfo];
    }
}

#pragma mark - private functions

- (double)distanceSquaredForLat1:(double)lat1 lng1:(double)lng1 lat2:(double)lat2 lng2:(double)lng2
{
    double radius = (3.14159265358979323846 / 180.0);
    double nauticalMilesPerLatitude = 60.00721;
    double nauticalMilesPerLongitude = 60.10793;
    double metersPerNauticalMile = 1852;
    // simple pythagorean formula - for efficiency
    float yDistance = (lat2 - lat1) * nauticalMilesPerLatitude;
    float xDistance = (cos(lat1 * radius) + cos(lat2 * radius)) * (lng2 - lng1) * (nauticalMilesPerLongitude / 2.0);
    return ((yDistance * yDistance) + (xDistance * xDistance)) * (metersPerNauticalMile * metersPerNauticalMile);
}

- (void)sendGeoLocationUpdate
{
    if (VisiGeofence.reportWorkHomeLocationOnly)
    {
        return; //not send logline 20.
    }
    if (self.currentGeoLocation.latitude == 0 || self.currentGeoLocation.longitude == 0)
    {
        return; //if current location is not detected, not send log 20.
    }
    if (self.reachability.currentReachabilityStatus != ReachableViaWiFi && self.reachability.currentReachabilityStatus != ReachableViaWWAN)
    {
        return; //only do location 20 when network available
    }
    BOOL isFG = ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground); //When asking for permission it's InActive
    double minTimeBWEvents = isFG ? self.fgMinTimeBetweenEvents * 60 : self.bgMinTimeBetweenEvents * 60;
    double minDistanceBWEvents = isFG ? self.fgMinDistanceBetweenEvents : self.bgMinDistanceBetweenEvents;
    NSTimeInterval timeDelta = [[NSDate date] timeIntervalSince1970] - self.sentGeoLocationTime;
    double distSquared = [self distanceSquaredForLat1:self.currentGeoLocation.latitude lng1:self.currentGeoLocation.longitude lat2:self.sentGeoLocationValue.latitude lng2:self.sentGeoLocationValue.longitude];
    double distanceDelta = sqrt(distSquared);
    if ((self.sentGeoLocationValue.latitude == 0 || self.sentGeoLocationValue.longitude == 0) //if not send before, do it anyway
        || ((timeDelta >= minTimeBWEvents) && (distanceDelta >= minDistanceBWEvents)))  //not push location change notification in certain time or in certain distance
    {
        NSDictionary *dictLoc = @{@"lat": @(self.currentGeoLocation.latitude), @"lng": @(self.currentGeoLocation.longitude)};
        DLog([NSString stringWithFormat:@"LocationManager Delegate: FG (%@), new location (%f, %f), old location (%f, %f), distance (%f >= %f), last time (%@), time delta (%f >= %f).", (isFG ? @"Yes" : @"No"), self.currentGeoLocation.latitude, self.currentGeoLocation.longitude, self.sentGeoLocationValue.latitude, self.sentGeoLocationValue.longitude, distanceDelta, minDistanceBWEvents, [NSDate dateWithTimeIntervalSince1970:self.sentGeoLocationTime], timeDelta, minTimeBWEvents]);
        self.sentGeoLocationValue = self.currentGeoLocation; //do it early
        self.sentGeoLocationTime = [[NSDate date] timeIntervalSince1970];
        //Only send logline 20 when have location bridge. Above check must kept here because the internal variables cannot move to SHLocationBridge.
        
        //TODO:visilabsSerializeObjToJson hata verdiği için sildim
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_SendGeoLocationLogline" object:nil userInfo:@{@"comment": NONULL(visilabsSerializeObjToJson(dictLoc))}];
        
    }
}

- (NSString *)formatBeaconRegion:(CLBeaconRegion *)region
{
    //major and minor can be null or int value, int value is from 0~65535. Check nil as nil.intValue=0.
    if (region.minor != nil)
    {
        return [NSString stringWithFormat:@"%@-%d-%d-%@", region.proximityUUID.UUIDString, region.major.intValue, region.minor.intValue, region.identifier];
    }
    if (region.major != nil)
    {
        return [NSString stringWithFormat:@"%@-%d-(null)-%@", region.proximityUUID.UUIDString, region.major.intValue, region.identifier];
    }
    return [NSString stringWithFormat:@"%@-(null)-(null)-%@", region.proximityUUID.UUIDString, region.identifier];
}

- (BOOL)isRegionSame:(CLRegion *)r1 with:(CLRegion *)r2
{
    if (r1 == nil && r2 == nil)
    {
        return YES;
    }
    //CLBeaconRegion isEqual is not correct, it compares memory, for example, after I change UUID it still return equal. So compare beacon region manually.
    if (r1 != nil && r2 != nil && [r1 isKindOfClass:[CLBeaconRegion class]] && [r2 isKindOfClass:[CLBeaconRegion class]])
    {
        CLBeaconRegion *br1 = (CLBeaconRegion *)r1;
        CLBeaconRegion *br2 = (CLBeaconRegion *)r2;
        if ([br1.proximityUUID.UUIDString compare:br2.proximityUUID.UUIDString options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            if ((br1.identifier == nil && br2.identifier == nil)
                || (br1.identifier != nil && br2.identifier != nil && [br1.identifier compare:br2.identifier options:NSCaseInsensitiveSearch] == NSOrderedSame))
            {
                if ((br1.major == nil && br2.major == nil) || (br1.major != nil && br2.major != nil && br1.major.intValue == br2.major.intValue))
                {
                    if ((br1.minor == nil && br2.minor == nil) || (br1.minor != nil && br2.minor != nil && br1.minor.intValue == br2.minor.intValue))
                    {
                        return YES;
                    }
                }
            }
        }
    }
    //CLCircularRegion compares identifier.
    if (r1 != nil && r2 != nil && [r1 isKindOfClass:[CLCircularRegion class]] && [r2 isKindOfClass:[CLCircularRegion class]])
    {
        CLCircularRegion *gr1 = (CLCircularRegion *)r1;
        CLCircularRegion *gr2 = (CLCircularRegion *)r2;
        return [gr1.identifier isEqualToString:gr2.identifier];
    }
    return [r1 isEqual:r2];
}

- (void)networkStatusChanged:(NSNotification *)notification
{
    if ([self updateRecoverTime]) //avoid 3G to Wifi two switch
    {
        [self sendGeoLocationUpdate]; //when network recover check whether need to send location update.
    }
}

- (BOOL)updateRecoverTime
{
    NSTimeInterval recoverTime = 0;
    NSObject *recoverTimeValue = [[NSUserDefaults standardUserDefaults] objectForKey:NETWORK_RECOVER_TIME];
    if (recoverTimeValue != nil && [recoverTimeValue isKindOfClass:[NSNumber class]])
    {
        recoverTime = [(NSNumber *)recoverTimeValue doubleValue];
    }
    if (self.reachability.currentReachabilityStatus == NotReachable)
    {
        if (recoverTime != 0)
        {
            [[NSUserDefaults standardUserDefaults] setDouble:0 forKey:NETWORK_RECOVER_TIME]; //not connected
            [[NSUserDefaults standardUserDefaults] synchronize];
            return YES;
        }
    }
    else
    {
        if (recoverTime == 0)
        {
            [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSinceReferenceDate] forKey:NETWORK_RECOVER_TIME]; //connected
            [[NSUserDefaults standardUserDefaults] synchronize];
            return YES;
        }
    }
    return NO; //not change
}

#pragma mark - CLLocationManagerDelegate implementation

/*
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    DLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    DLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
}
 */

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations  //since iOS 6.0
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    if (locations.count > 0)
    {
        CLLocationCoordinate2D previousLocation = self.currentGeoLocation;
        self.currentGeoLocationValue = ((CLLocation *)locations[0]).coordinate;  //no matter sent log or not, keep current geo location fresh.
        [self sendGeoLocationUpdate];
        //send out notification for location change
        CLLocation *oldLocation = [[CLLocation alloc] initWithLatitude:previousLocation.latitude longitude:previousLocation.longitude];
        NSDictionary *userInfo = @{SHLMNotification_kNewLocation:locations[0], SHLMNotification_kOldLocation: oldLocation};
        NSNotification *notification = [NSNotification notificationWithName:SHLMUpdateLocationSuccessNotification object:self userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    if (error.code == kCLErrorDenied)  //location service is denied by user
    {
        NSString *sentFlag = [[NSUserDefaults standardUserDefaults] objectForKey:LOCATION_DENIED_SENT];
        if ((sentFlag == nil || sentFlag.length == 0))
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"Sent" forKey:LOCATION_DENIED_SENT];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    else
    {
        DLog(@"LocationManager Delegate: Update Failed: %@", [error localizedDescription]);
    }
    NSDictionary *userInfo = @{SHLMNotification_kError: error != nil ? error : [NSError errorWithDomain:SHErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"Location service update fail."}]};
    NSNotification *notification = [NSNotification notificationWithName:SHLMUpdateFailNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(void) sendPushNotification:(NSString *)actID withGeofenceID:(NSString *)geofenceID withIsDwell:(BOOL) isDwell withIsEnter:(BOOL) isEnter
{
    VisilabsGeofenceRequest *request=[[Visilabs callAPI] buildGeofenceRequest:@"processV2" withActionID: actID withLatitude:0 withLongitude:0 withGeofenceID:geofenceID withIsDwell:isDwell withIsEnter:isEnter];
    void (^ successBlock)(VisilabsResponse *) = ^(VisilabsResponse * response) {};
    void (^ failBlock)(VisilabsResponse *) =^(VisilabsResponse * response){};
    [request execAsyncWithSuccess:successBlock AndFailure:failBlock];
    
}
/*
-(void) checkDwell:(NSTimer*)theTimer
{
    NSString *geofenceID =  (NSString*)[theTimer userInfo];
    NSArray *geofences = [[VisilabsGeofenceStatus sharedInstance] arrayGeofenceFetchList];
    if(geofences){
        for (VisilabsServerGeofence *geofence in geofences){
            if([geofence.suid isEqualToString:geofenceID]){
            
                if(geofence.isInside){
                    NSArray *elements = [geofenceID componentsSeparatedByString:@"_"];
                    if(elements && elements.count >= 3){
                        [[VisilabsGeofenceLocationManager sharedInstance] sendPushNotification:elements[1]];
                    }
                }
                return;
            }
        }
    }
    
}
 */

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    DLog(@"LocationManager Delegate: Enter Region: %@", region.identifier);

    NSArray *geofences = [[VisilabsGeofenceStatus sharedInstance] arrayGeofenceFetchList];
    if(geofences){
        for (VisilabsServerGeofence *geofence in geofences){
            if([geofence.suid isEqualToString:region.identifier]){
                NSArray *elements = [region.identifier componentsSeparatedByString:@"_"];
                if([geofence.type isEqualToString:@"OnEnter"]){
                    if(elements && elements.count >= 6){
                        NSString * geoID = elements[5];
                        [[VisilabsGeofenceLocationManager sharedInstance] sendPushNotification:elements[1] withGeofenceID: geoID withIsDwell:NO withIsEnter:NO] ;
                    }
                }
                else if([geofence.type isEqualToString:@"Dwell"]){
                    if(elements && elements.count >= 6){
                        NSString * geoID = elements[5];
                        [[VisilabsGeofenceLocationManager sharedInstance] sendPushNotification:elements[1] withGeofenceID: geoID withIsDwell:YES withIsEnter:YES] ;
                    }
                }
                
                
                /*
                else if([geofence.type isEqualToString:@"Dwell"]){                   
                    if(_geofenceDwellTimers == nil)
                    {
                        _geofenceDwellTimers = [[NSMutableDictionary alloc] init];
                    }
                    if([_geofenceDwellTimers objectForKey:geofence.suid] != nil)
                    {
                        NSTimer * previousTimer = _geofenceDwellTimers[geofence.suid];
                        [previousTimer invalidate];
                        previousTimer = nil;
                        _geofenceDwellTimers[geofence.suid] = nil;
                    }
                    NSTimer *dwellTimer = [NSTimer scheduledTimerWithTimeInterval:geofence.durationInSeconds
                                                                           target:self
                                                                         selector:@selector(checkDwell:)
                                                                         userInfo:geofence.suid
                                                                          repeats:NO];
                    [_geofenceDwellTimers setObject:dwellTimer forKey:geofence.suid];
                    
                }
                */
            }
        }
    }
    

    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    NSDictionary *userInfo = @{SHLMNotification_kRegion: region};
    NSNotification *notification = [NSNotification notificationWithName:SHLMEnterRegionNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
     DLog(@"LocationManager Delegate: Exit Region: %@", region.identifier);
    NSArray *geofences = [[VisilabsGeofenceStatus sharedInstance] arrayGeofenceFetchList];
    if(geofences){
        for (VisilabsServerGeofence *geofence in geofences){
            if([geofence.suid isEqualToString:region.identifier]){
                NSArray *elements = [region.identifier componentsSeparatedByString:@"_"];
                if([geofence.type isEqualToString:@"OnExit"]){
                    if(elements && elements.count >= 6){
                        NSString * geoID = elements[5];
                        [[VisilabsGeofenceLocationManager sharedInstance] sendPushNotification:elements[1] withGeofenceID:geoID withIsDwell:NO withIsEnter:NO];
                    }
                }
                else if([geofence.type isEqualToString:@"Dwell"]){
                    if(elements && elements.count >= 6){
                        NSString * geoID = elements[5];
                        [[VisilabsGeofenceLocationManager sharedInstance] sendPushNotification:elements[1] withGeofenceID: geoID withIsDwell:YES withIsEnter:NO] ;
                    }
                }
            }
        }
    }
    
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    DLog(@"LocationManager Delegate: Exit Region: %@", region);
    NSDictionary *userInfo = @{SHLMNotification_kRegion: region};
    NSNotification *notification = [NSNotification notificationWithName:SHLMExitRegionNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    DLog(@"LocationManager Delegate: Monitoring started for region: %@", region);
    NSDictionary *userInfo = @{SHLMNotification_kRegion: region};
    NSNotification *notification = [NSNotification notificationWithName:SHLMMonitorRegionSuccessNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    //If iBeacon inside region, previous launch is inside region, this time will not trigger delegate until cross border. To not igore this time, forcibily to trigger status delegate.
    if ([self.locationManager respondsToSelector:@selector(requestStateForRegion:)])
    {
        [self.locationManager requestStateForRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    DLog(@"LocationManager Delegate: Monitoring Failed for Region(%@): %@", region, [error localizedDescription]);
    NSDictionary *userInfo = @{SHLMNotification_kRegion: region, SHLMNotification_kError: error};
    NSNotification *notification = [NSNotification notificationWithName:SHLMMonitorRegionFailNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    NSString *strState = nil;
    switch (state)
    {
        case CLRegionStateUnknown:
            strState = @"\"unknown\"";
            break;
        case CLRegionStateInside:
            strState = @"\"inside\"";
            break;
        case CLRegionStateOutside:
            strState = @"\"outside\"";
            break;
        default:
            break;
    }
    DLog(@"LocationManager Delegate: Determine State %@ for Region %@", strState, region);
    NSDictionary *userInfo = @{SHLMNotification_kRegion: region, SHLMNotification_kRegionState: @(state)};
    NSNotification *notification = [NSNotification notificationWithName:SHLMRegionStateChangeNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    DLog(@"LocationManager Delegate: did range beacons: %@ for region: %@.", beacons, region);
    NSDictionary *userInfo = @{SHLMNotification_kRegion: region, SHLMNotification_kBeacons: beacons};
    NSNotification *notification = [NSNotification notificationWithName:SHLMRangeiBeaconChangedNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    DLog(@"LocationManager Delegate: range location Failed for Region(%@): %@", region, [error localizedDescription]);
    NSDictionary *userInfo = @{SHLMNotification_kRegion: region, SHLMNotification_kError: error};
    NSNotification *notification = [NSNotification notificationWithName:SHLMRangeiBeaconFailNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;  //initialize CLLocationManager but cannot call any function to avoid promote.
    }
    NSString *authStatus = nil;
    switch (status)
    {
        case kCLAuthorizationStatusNotDetermined:
            authStatus = @"Not determinded";
            break;
        case kCLAuthorizationStatusRestricted:
            authStatus = @"Restricted";
            break;
        case kCLAuthorizationStatusDenied:
            authStatus = @"Denied";
            break;
        case kCLAuthorizationStatusAuthorizedAlways: //equal kCLAuthorizationStatusAuthorized (3)
            authStatus = @"Always Authorized";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            authStatus = @"When in Use";
            break;
        default:
            break;
    }
    DLog(@"LocationManager Delegate: Authorisation status changed: %@.", authStatus);
    NSDictionary *userInfo = @{SHLMNotification_kAuthStatus: [NSNumber numberWithInt:status]};
    NSNotification *notification = [NSNotification notificationWithName:SHLMChangeAuthorizationStatusNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end
