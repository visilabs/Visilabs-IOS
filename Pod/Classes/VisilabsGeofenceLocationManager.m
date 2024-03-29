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
@property (nonatomic) CLLocationCoordinate2D sentGeoLocationValue; //sent by log location 20
@property (nonatomic) NSTimeInterval sentGeoLocationTime;  //for calculate time delta to prevent too often location update notification send.

- (void)createLocationManager;  //create internal operating iOS object.
- (double)distanceSquaredForLat1:(double)lat1 lng1:(double)lng1 lat2:(double)lat2 lng2:(double)lng2;
- (void)sendGeoLocationUpdate;

- (BOOL)isRegionSame:(CLRegion *)r1 with:(CLRegion *)r2;

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
    
    if(self.locationManager.location != nil) {
        self.currentGeoLocationValue = self.locationManager.location.coordinate;
    } else {
        self.currentGeoLocationValue = CLLocationCoordinate2DMake(0, 0);
    }
    
    
    
    self.sentGeoLocationValue = CLLocationCoordinate2DMake(0, 0);
    self.sentGeoLocationTime = 0;
    _geolocationMonitorState = SHGeoLocationMonitorState_Stopped;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SH_LMBridge_StartMonitorGeoLocation" object:nil];
    
    if ([CLLocationManager significantLocationChangeMonitoringAvailable])
    {
        DLog(@"LocationManager Action: Start significant location update.");
        [self.locationManager startMonitoringSignificantLocationChanges];
        _geolocationMonitorState = SHGeoLocationMonitorState_MonitorSignificant;
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
    if ([[UIDevice currentDevice].systemVersion doubleValue] >= 8.0)
    {
        NSString *locationAlwaysStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"];
        NSString *locationWhileInUseStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"];
        NSString *locationAlwaysAndWhenInUseStr  = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysAndWhenInUseUsageDescription"];
        if (locationAlwaysStr == nil && locationWhileInUseStr == nil && locationAlwaysAndWhenInUseStr == nil)
        {
            return NO;
        }
    }
    if (!VisiGeofence.isLocationServiceEnabled || ![CLLocationManager locationServicesEnabled])
    {
        return NO;
    }
    BOOL isEnabled;
    if (allowNotDetermined)
    {
        isEnabled = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways
                     || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse
                     || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined
                     || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways);
    }
    else
    {
        isEnabled = ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways
                     || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse);
    }
    if (isEnabled)
    {
        NSString *sentFlag = [[NSUserDefaults standardUserDefaults] objectForKey:LOCATION_DENIED_SENT];
        if (sentFlag != nil && sentFlag.length > 0)
        {
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
    
    NSString *locationWhileInUseStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"];
    NSString *locationAlwaysStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"];
    NSString *locationAlwaysAndWhenInUseStr = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysAndWhenInUseUsageDescription"];
    if (enabled && status == kCLAuthorizationStatusNotDetermined)
    {
        if (locationAlwaysStr != nil || locationAlwaysAndWhenInUseStr)
        {
            if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
            {
                [self.locationManager requestAlwaysAuthorization];
            }
        }
        else
        {
            if (locationWhileInUseStr != nil)
            {
                if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
                {
                    [self.locationManager requestWhenInUseAuthorization];
                }
            }
        }
    }
    
    if (@available(iOS 13.4, *)) {
        if (enabled && status == kCLAuthorizationStatusAuthorizedWhenInUse)
        {
            if (locationAlwaysStr != nil || locationAlwaysAndWhenInUseStr)
            {
                if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
                {
                    [self.locationManager requestAlwaysAuthorization];
                }
            }
        }
    }
}

- (BOOL)startMonitorGeoLocationStandard:(BOOL)standard
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return NO;
    }
    [self requestPermissionSinceiOS8];
    if (self.geolocationMonitorState == SHGeoLocationMonitorState_Stopped
        || (standard && self.geolocationMonitorState == SHGeoLocationMonitorState_MonitorSignificant)
        || (!standard && self.geolocationMonitorState == SHGeoLocationMonitorState_MonitorStandard))  //avoid stop and start for the same mode
    {
        if ([VisilabsGeofenceLocationManager locationServiceEnabledForApp:YES])
        {
            [self stopMonitorGeoLocation];
            if (standard)
            {
                DLog(@"LocationManager Action: Start standard location update.");
                [self.locationManager startUpdatingLocation];
                _geolocationMonitorState = SHGeoLocationMonitorState_MonitorStandard;
                [[NSNotificationCenter defaultCenter] postNotificationName:SHLMStartStandardMonitorNotification object:self];
            }
            else
            {
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
        return;
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
        DLog(@"%@", [NSString stringWithFormat:@"LocationManager Delegate: FG (%@), new location (%f, %f), old location (%f, %f), distance (%f >= %f), last time (%@), time delta (%f >= %f).", (isFG ? @"Yes" : @"No"), self.currentGeoLocation.latitude, self.currentGeoLocation.longitude, self.sentGeoLocationValue.latitude, self.sentGeoLocationValue.longitude, distanceDelta, minDistanceBWEvents, [NSDate dateWithTimeIntervalSince1970:self.sentGeoLocationTime], timeDelta, minTimeBWEvents]);
        self.sentGeoLocationValue = self.currentGeoLocation;
        self.sentGeoLocationTime = [[NSDate date] timeIntervalSince1970];
    }
}

- (BOOL)isRegionSame:(CLRegion *)r1 with:(CLRegion *)r2
{
    if (r1 == nil && r2 == nil)
    {
        return YES;
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
            }
        }
    }
    
    
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;
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
        return;
    }
    DLog(@"LocationManager Delegate: Monitoring started for region: %@", region);
    NSDictionary *userInfo = @{SHLMNotification_kRegion: region};
    NSNotification *notification = [NSNotification notificationWithName:SHLMMonitorRegionSuccessNotification object:self userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    if ([self.locationManager respondsToSelector:@selector(requestStateForRegion:)])
    {
        [self.locationManager requestStateForRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;
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
        return;
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

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (!VisiGeofence.isLocationServiceEnabled)
    {
        return;
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
        case kCLAuthorizationStatusAuthorizedAlways:
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
