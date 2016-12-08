//
//  VisilabsGeofenceStatus.m
//  Pods
//
//  Created by Visilabs on 15.08.2016.
//
//

#import "VisilabsDefines.h"
#import "VisilabsGeofenceStatus.h"
#import "VisilabsGeofenceApp.h"
#import "VisilabsGeofenceLocationManager.h"

#import "Visilabs.h"
#import "VisilabsGeofenceRequest.h"



#define APPSTATUS_GEOFENCE_FETCH_TIME       @"APPSTATUS_GEOFENCE_FETCH_TIME"  //last successfully fetch geofence list time
#define APPSTATUS_GEOFENCE_FETCH_LIST       @"APPSTATUS_GEOFENCE_FETCH_LIST"  //geofence list fetched from server, it contains parent geofence with child node. This is used as geofence monitor region.



@interface VisilabsGeofenceStatus ()

//@property (strong, nonatomic) NSMutableArray *arrayGeofenceFetchList; //simiar as above but for geofence fetch list.
- (void)sendLogForGeoFence:(VisilabsServerGeofence *)geoFence isInside:(BOOL)isInside; //Send install/log for enter/exit server geofence.
- (VisilabsServerGeofence *)findServerGeofenceForRegion:(CLRegion *)region;  //get VisilabsServerGeofence list, subset of self.arrayGeofenceFetchList, which match this region. It searches both parent and child list.
- (void)stopMonitorPreviousGeofencesOnlyForOutside:(BOOL)onlyForOutside parentCanKeepChild:(BOOL)parentKeep;  //Geofence monitor region need to change, stop previous monitor for server's geofence. If `onlyForOutside`=YES, only stop monitor those outside; otherwise stop all regardless inside or outside. `parentKeep`=YES take effect when `onlyForOutside`=YES, if it's parent fence is inside, child fence not stop although it's outside.
- (void)startMonitorGeofences:(NSArray *)arrayGeofences;  //Give an array of VisilabsServerGeofence and convert to be monitored. It doesn't create region for child nodes.
- (void)markSelfAndChildGeofenceOutside:(VisilabsServerGeofence *)geofence; //When a geofence outside, mark itself and child (if has) to be outside, send out geofene logline for previous inside leave geofence too. Make it a separate function because it's recurisive.
- (void)stopMonitorSelfAndChildGeofence:(VisilabsServerGeofence *)geofence; //when stop monitor inner geofence, stop monitor its child too. As child not stop when exit due to parent keep it.
- (VisilabsServerGeofence *)searchSelfAndChild:(VisilabsServerGeofence *)geofence forRegion:(CLCircularRegion *)geoRegion; //search recursively to match
- (void)regionStateChangeNotificationHandler:(NSNotification *)notification; //monitor when a region state change.



@end

@implementation VisilabsGeofenceStatus

@synthesize arrayGeofenceFetchList = _arrayGeofenceFetchList;

#pragma mark - life cycle

+ (VisilabsGeofenceStatus *)sharedInstance
{
    static VisilabsGeofenceStatus *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      instance = [[VisilabsGeofenceStatus alloc] init];
                  });
    return instance;
}

- (id)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regionStateChangeNotificationHandler:) name:SHLMRegionStateChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - properties

- (NSString *)geofenceTimestamp
{
    NSAssert(NO, @"Should not call geofenceTimestamp.");
    return nil;
}

NSDateFormatter *visilabsGetDateFormatter(NSString *dateFormat, NSTimeZone *timeZone, NSLocale *locale)
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if (dateFormat == nil)
    {
        dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    [dateFormatter setDateFormat:dateFormat];
    if (timeZone == nil)
    {
        timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    }
    [dateFormatter setTimeZone:timeZone];
    if (locale == nil)
    {
        locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    }
    [dateFormatter setLocale:locale];
    return dateFormatter;
}

BOOL visilabsStrIsEmpty(NSString *str)
{
    return (str == nil || str.length == 0);
}

NSDate *visilabsParseDate(NSString *input, int offsetSeconds)
{
    static dispatch_semaphore_t formatter_semaphore;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter_semaphore = dispatch_semaphore_create(1);
    });
    NSDate *out = nil;
    if ([input isKindOfClass:[NSString class]] && !visilabsStrIsEmpty(input) && input != (id)[NSNull null])
    {
        dispatch_semaphore_wait(formatter_semaphore, DISPATCH_TIME_FOREVER);
        NSDateFormatter *dateFormatter = visilabsGetDateFormatter(nil, nil, nil);
        out = [dateFormatter dateFromString:input];
        if (out == nil)
        {
            [dateFormatter setDateFormat:@"yyyy-MM-dd"];
            out = [dateFormatter dateFromString:input];
        }
        if (out == nil)
        {
            [dateFormatter setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
            out = [dateFormatter dateFromString:input];
        }
        if (out == nil)
        {
            [dateFormatter setDateFormat:@"dd/MM/yyyy"];
            out = [dateFormatter dateFromString:input];
        }
        if (out == nil)
        {
            [dateFormatter setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
            out = [dateFormatter dateFromString:input];
        }
        if (out == nil)
        {
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            out = [dateFormatter dateFromString:input];
        }
        dispatch_semaphore_signal(formatter_semaphore);
        if (offsetSeconds != 0)
        {
            out = [NSDate dateWithTimeInterval:offsetSeconds sinceDate:out];
        }
    }
    return out;
}

- (void)setGeofenceTimestamp:(NSString *)geofenceTimestamp
{
    if (![VisilabsGeofenceLocationManager locationServiceEnabledForApp:NO] || ![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]])
    {
        return;
    }
    if (geofenceTimestamp != nil && [geofenceTimestamp isKindOfClass:[NSString class]])
    {
        NSDate *serverTime = visilabsParseDate(geofenceTimestamp, 0);
        if (serverTime != nil)
        {
            BOOL needFetch = NO;
            NSObject *localTimeVal = [[NSUserDefaults standardUserDefaults] objectForKey:APPSTATUS_GEOFENCE_FETCH_TIME];
            if (localTimeVal == nil || ![localTimeVal isKindOfClass:[NSNumber class]])
            {
                needFetch = YES;  //local never fetched, do fetch.
            }
            else
            {
                //NSDate *localTime = [NSDate dateWithTimeIntervalSinceReferenceDate:[(NSNumber *)localTimeVal doubleValue]];
                
                //TODO:egemen karşılaştırmayı yapmıyor artık.
                needFetch = YES;
                /*
                if ([localTime compare:serverTime] == NSOrderedAscending)
                {
                    needFetch = YES;  //local fetched, but too old, do fetch.
                }
                */
            }
            if (needFetch)
            {
                //update local cache time before send request, because this request has same format as others {app_status:..., code:0, value:...}, it will trigger `setGeofenceTimestamp` again. If fail to get request, clear local cache time in callback handler, make next fetch happen.
                [[NSUserDefaults standardUserDefaults] setObject:@([serverTime timeIntervalSinceReferenceDate]) forKey:APPSTATUS_GEOFENCE_FETCH_TIME];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                
                
                
                VisilabsGeofenceRequest *request=[[Visilabs callAPI] buildGeofenceRequest:@"getlist" withActionID: nil];
                void (^ successBlock)(VisilabsResponse *) = ^(VisilabsResponse * response) {
                    NSMutableArray *returnedRegions = [[NSMutableArray alloc] init];
                    
                    DLog(@"Response: %@", response.rawResponseAsString);
                    NSArray *parsedArray = [response responseArray];
                    if(parsedArray){
                        
                        int i = 0;
                        
                        for (NSObject * object in parsedArray) {
                            if([object isKindOfClass:[NSDictionary class]]){
                                NSDictionary *action = (NSDictionary*)object;
                                int actid = [[action objectForKey:@"actid"] intValue];
                                NSString *targetEvent = [action objectForKey:@"trgevt"];
                                int durationInSeconds = [[action objectForKey:@"dis"] intValue];
                                NSObject *geoFences = [action objectForKey:@"geo"];
                                
                                //VisilabsGFRegion *regionDict = [[VisilabsGFRegion alloc] init];
                                //NSObject *regionDict = [[NSObject alloc] init];
                                
                                if(geoFences){
                                    NSArray *geoFencesArray = (NSArray *)geoFences;
                                    
                                    
                                    
                                    for (NSObject * geo in geoFencesArray) {
                                        if([geo isKindOfClass:[NSDictionary class]]){
                                            
                                            NSDictionary *geofence = (NSDictionary*)geo;
                                            double latitude = [[geofence objectForKey:@"lat"] doubleValue];
                                            double longitude = [[geofence objectForKey:@"long"] doubleValue];
                                            double radius = [[geofence objectForKey:@"rds"] doubleValue];
                                            
                                            VisilabsServerGeofence *visilabsServerGeofence = [[VisilabsServerGeofence alloc] init];
                                            visilabsServerGeofence.serverId = [NSString stringWithFormat:@"%d_%d", actid, i];
                                            visilabsServerGeofence.suid = [NSString stringWithFormat:@"%d_%d", actid, i];
                                            visilabsServerGeofence.title = [NSString stringWithFormat:@"%d_%d", actid, i];
                                            
                                            visilabsServerGeofence.latitude = latitude;
                                            visilabsServerGeofence.longitude = longitude;
                                            visilabsServerGeofence.radius = radius;
                                            
                                            visilabsServerGeofence.isInside = NO;
                                            //visilabsServerGeofence.isLeaves = NO;
                                            
                                            visilabsServerGeofence.type = targetEvent;
                                            visilabsServerGeofence.durationInSeconds = durationInSeconds;
                                            
                                            visilabsServerGeofence.distanceFromCurrentLastKnownLocation = DBL_MAX;
                                            
                                            CLLocationCoordinate2D currentLocation =  [[VisilabsGeofenceLocationManager sharedInstance] currentGeoLocationValue];
                                            CLLocationDegrees currentLatitude = currentLocation.latitude;
                                            CLLocationDegrees currentLongitude = currentLocation.longitude;
                                            
                                            double distance = [self distanceSquaredForLat1:visilabsServerGeofence.latitude lng1:visilabsServerGeofence.longitude lat2:currentLatitude lng2: currentLongitude];
                                            
                                            visilabsServerGeofence.distanceFromCurrentLastKnownLocation = distance;
                                            
                                            [returnedRegions addObject:visilabsServerGeofence];
                                            
                                            if(i == 0){
                                                DLog(@"Current latitude: %g longitude:%g", currentLatitude, currentLongitude);
                                            }
                                            
                                            i = i+1;
                                            /*
                                            NSMutableDictionary *regionDict = [[NSMutableDictionary alloc] init];
                                            [regionDict visilabsSetObject:[NSString stringWithFormat:@"%d_%d", actid, i] forKey:@"id"];
                                            [regionDict visilabsSetObject:[NSString stringWithFormat:@"%d_%d", actid, i] forKey:@"name"];
                                            [regionDict visilabsSetObject:[NSNumber numberWithDouble:radius] forKey:@"radiusMetres"];
                                            [regionDict visilabsSetObject:@{@"longitude":[NSNumber numberWithDouble:longitude],
                                                                            @"latitude":[NSNumber numberWithDouble:latitude]} forKey:@"centrePoint"];
                                            [regionDict visilabsSetObject:@"Active" forKey:@"status"];
                                            [returnedRegions addObject:regionDict];
                                             */
                                        }
                                    }
                                    
                                }
                                
                            }
                        }
                        
                        
                        //Geofence would monitor parent or child, and it's possible `id` not change but latitude/longitude/radius change. When timestamp change, stop monitor existing geofences and start to monitor from new list totally.
                        [self stopMonitorPreviousGeofencesOnlyForOutside:NO parentCanKeepChild:NO]; //server's geofence change, stop monitor all.
                        //Update local cache and memory, start monitor parent.

                        
                        @try{
                            if(returnedRegions && [returnedRegions count] > 20){
                                NSSortDescriptor *sortDescriptor;
                                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distanceFromCurrentLastKnownLocation"
                                                                         ascending:YES];
                                NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
                                NSArray *sortedReturnedRegions = [returnedRegions sortedArrayUsingDescriptors:sortDescriptors];
                                returnedRegions = [sortedReturnedRegions subarrayWithRange:NSMakeRange(0, 20)];
                            }
                        }@catch(NSException *ex){
                            
                        }
                        
                        self.arrayGeofenceFetchList = returnedRegions;
                        [[NSUserDefaults standardUserDefaults] setObject:[VisilabsServerGeofence serializeToArrayDict:returnedRegions] forKey:APPSTATUS_GEOFENCE_FETCH_LIST];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [self startMonitorGeofences:returnedRegions];

                        

                    }
                };
                
                void (^ failBlock)(VisilabsResponse *) =^(VisilabsResponse * response){

                };
                
                [request execAsyncWithSuccess:successBlock AndFailure:failBlock];
                
            }
            return;
        }
    }
    //when meet this, means server return nil or invalid timestamp. Clear local fetch list and stop monitor.
    [self stopMonitorPreviousGeofencesOnlyForOutside:NO parentCanKeepChild:NO];
    self.arrayGeofenceFetchList = [NSMutableArray array]; //cannot set to nil, as nil will read from NSUserDefaults again.
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:APPSTATUS_GEOFENCE_FETCH_LIST];  //clear local cache, not start when kill and launch App.
    [[NSUserDefaults standardUserDefaults] synchronize];
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

/*
float const HAVERSINE_RADS_PER_DEGREE = 0.0174532925199433;

- (float)distance:(float)lat1 lon1:(float)lat2 lat2:(float)lon1 lon2:(float)lon2 {
    float lat1Rad = lat1 * HAVERSINE_RADS_PER_DEGREE;
    float lat2Rad = lat2 * HAVERSINE_RADS_PER_DEGREE;
    float dLonRad = ((lon2 - lon1) * HAVERSINE_RADS_PER_DEGREE);
    float dLatRad = ((lat2 - lat1) * HAVERSINE_RADS_PER_DEGREE);
    float a = pow(sin(dLatRad / 2), 2) + cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLonRad / 2), 2);
    return (2 * atan2(sqrt(a), sqrt(1 - a)));
}
 */

- (NSMutableArray *)arrayGeofenceFetchList
{
    if (_arrayGeofenceFetchList == nil) //never initialized
    {
        _arrayGeofenceFetchList = [NSMutableArray arrayWithArray:[VisilabsServerGeofence deserializeToArrayObj:[[NSUserDefaults standardUserDefaults] objectForKey:APPSTATUS_GEOFENCE_FETCH_LIST]]]; //it will not get nil even empty
    }
    return _arrayGeofenceFetchList;
}

- (void)sendLogForGeoFence:(VisilabsServerGeofence *)geoFence isInside:(BOOL)isInside
{
    return;
}

- (VisilabsServerGeofence *)findServerGeofenceForRegion:(CLRegion *)region
{
    if (![region isKindOfClass:[CLCircularRegion class]])
    {
        return nil;
    }
    CLCircularRegion *geoRegion = (CLCircularRegion *)region;
    for (VisilabsServerGeofence *geofence in self.arrayGeofenceFetchList)
    {
        VisilabsServerGeofence *matchGeofence = [self searchSelfAndChild:geofence forRegion:geoRegion];
        if (matchGeofence != nil)
        {
            return matchGeofence;
        }
    }
    return nil;
}

- (void)stopMonitorPreviousGeofencesOnlyForOutside:(BOOL)onlyForOutside parentCanKeepChild:(BOOL)parentKeep
{
    for (CLRegion *monitorRegion in VisiGeofence.locationManager.monitoredRegions)
    {
        //only stop if this region is previous geofence, should not affect if it's iBeacon or from other source monitor.
        VisilabsServerGeofence *matchGeofence = [self findServerGeofenceForRegion:monitorRegion];
        if (matchGeofence != nil) //stop monitor this as it's previous geofence
        {
            BOOL shouldStop = YES;
            if (onlyForOutside) //otherwise for both inside and outside, means stop all
            {
                if (matchGeofence.isInside)  //this one is inside, cannot stop
                {
                    shouldStop = NO;
                }
                else
                {
                    if (parentKeep && matchGeofence.parentFence != nil && matchGeofence.parentFence.isInside) //although this one is outside, but its parent is inside and can keep it.
                    {
                        shouldStop = NO;
                    }
                }
            }
            if (shouldStop)
            {
                //Test multiple levels case: level1 inner->level 2 inner->leave. Before exit it's inside leave. Suddenly exit them all, when exit leave it's kept monitor by level 2, when exit level 2 it stops monitor, but still leave is monitor. In this case should remove level geofence too.
                [self stopMonitorSelfAndChildGeofence:matchGeofence];
            }
        }
    }
}

- (void)startMonitorGeofences:(NSArray *)arrayGeofences
{
    for (VisilabsServerGeofence *geofence in arrayGeofences)
    {
        [VisiGeofence.locationManager startMonitorRegion:[geofence getGeoRegion]];
    }
}

- (void)markSelfAndChildGeofenceOutside:(VisilabsServerGeofence *)geofence
{
    if (geofence.isInside)
    {
        geofence.isInside = NO;
        if (geofence.isLeaves) //for leave go outside, send logline.
        {
            [self sendLogForGeoFence:geofence isInside:NO];
        }
        else //if parent geofence out, make all child geofence outside too.
        {
            for (VisilabsServerGeofence *childGeofence in geofence.arrayNodes)
            {
                [self markSelfAndChildGeofenceOutside:childGeofence]; //recurisively do it as child geofence may contains child too.
            }
        }
    }
}

- (void)stopMonitorSelfAndChildGeofence:(VisilabsServerGeofence *)geofence
{
    [VisiGeofence.locationManager stopMonitorRegion:[geofence getGeoRegion]];
    if (!geofence.isLeaves)
    {
        for (VisilabsServerGeofence *childGeofence in geofence.arrayNodes)
        {
            [self stopMonitorSelfAndChildGeofence:childGeofence]; //recurisively do it as child geofence may contains child too.
        }
    }
}

- (VisilabsServerGeofence *)searchSelfAndChild:(VisilabsServerGeofence *)geofence forRegion:(CLCircularRegion *)geoRegion
{
    if ([geofence isEqualToCircleRegion:geoRegion])
    {
        return geofence;
    }
    for (VisilabsServerGeofence *childGeoFence in geofence.arrayNodes)
    {
        VisilabsServerGeofence *match = [self searchSelfAndChild:childGeoFence forRegion:geoRegion];
        if (match != nil)
        {
            return match;
        }
    }
    return nil;
}

- (void)regionStateChangeNotificationHandler:(NSNotification *)notification
{
    //use state change instead of didEnterRegion/didExitRegion because when startMonitorRegion, state change delegate is called, didEnter/ExitRegion delegate not called until next enter/exit.
    CLRegion *region = notification.userInfo[SHLMNotification_kRegion];
    CLRegionState regionState = [notification.userInfo[SHLMNotification_kRegionState] intValue];
    if (regionState == CLRegionStateInside)
    {
        if ([region isKindOfClass:[CLCircularRegion class]])
        {
            VisilabsServerGeofence *geofence = [self findServerGeofenceForRegion:region];
            if (geofence != nil && !geofence.isInside/*only take action if change*/)
            {
                geofence.isInside = YES;
                [[NSUserDefaults standardUserDefaults] setObject:[VisilabsServerGeofence serializeToArrayDict:self.arrayGeofenceFetchList] forKey:APPSTATUS_GEOFENCE_FETCH_LIST];
                [[NSUserDefaults standardUserDefaults] synchronize];
                if (geofence.isLeaves) //if this is actual geofence, send enter logline and it's done
                {
                    [self sendLogForGeoFence:geofence isInside:YES];
                }
                else //if this is parent geofence, stop monitor other outside parent geofence and add self's child node.
                {
                    [self stopMonitorPreviousGeofencesOnlyForOutside:YES parentCanKeepChild:YES]; //This is a tricky: parent fence may overlap. Case 1: simple case, if parent fence not overlap, enter this one means all others are outside, so stop all other parent fences and add this one's child. Case 2: if parent fence P1 overlap with parent fence P2, P1 is already inside, now enter P2. This check will keep P1 and P1's child fence in monitoring, while later add P2 and its child.
                    [self startMonitorGeofences:geofence.arrayNodes]; //geofence itself is already monitor
                }
            }
        }
    }
    else if (regionState == CLRegionStateOutside)
    {
        if ([region isKindOfClass:[CLCircularRegion class]])
        {
            VisilabsServerGeofence *geofence = [self findServerGeofenceForRegion:region];
            if (geofence != nil && geofence.isInside/*only take action if change*/)
            {
                [self markSelfAndChildGeofenceOutside:geofence]; //recursively mark this geofence and its child all outside. It also sends exit logline for child if necessary, because if parent exit before child leave, child will be marked as outside, and this logic will not enter when child leave detect outside.
                [[NSUserDefaults standardUserDefaults] setObject:[VisilabsServerGeofence serializeToArrayDict:self.arrayGeofenceFetchList] forKey:APPSTATUS_GEOFENCE_FETCH_LIST];
                [[NSUserDefaults standardUserDefaults] synchronize];
                if (!geofence.isLeaves) //if this is inner geofence, stop monitor its child geofence, add itself and it's same level.
                {
                    [self stopMonitorPreviousGeofencesOnlyForOutside:YES parentCanKeepChild:YES]; //in case overlap and in another parent geofence, this will keep it un-affected.
                    if (geofence.parentFence != nil && geofence.parentFence.isInside)
                    {
                        //Move out from a inner geofence, if its parent geofence is still inside, monitor itself and its same level. Cannot monitor top level in this case, because if monitor top level, its parent fence is already monitored, and not stop/add again, no enter happens, so the same level geofence (some maybe leave geofence), will not be monitored.
                        [self startMonitorGeofences:geofence.parentFence.arrayNodes];
                    }
                    else
                    {
                        [self startMonitorGeofences:self.arrayGeofenceFetchList]; //monitor all top level geofences.
                    }
                }
            }
        }
    }
    //do nothing for state=unknown.
}

@end

@implementation VisilabsServerGeofence

@synthesize serverId = _serverId;
@synthesize latitude = _latitude;
@synthesize longitude = _longitude;
@synthesize radius = _radius;
@synthesize isLeaves = _isLeaves;
@synthesize type = _type;
@synthesize durationInSeconds = _durationInSeconds;

#pragma mark - life cycle

- (id)init
{
    if (self = [super init])
    {
        self.parentFence = nil;
        self.arrayNodes = [NSMutableArray array];
        self.isInside = NO;
    }
    return self;
}

#pragma mark - properties

- (void)setServerId:(NSString *)serverId
{
    NSAssert(!visilabsStrIsEmpty(serverId), @"Invalid geofence server Id.");
    _serverId = serverId;
    _isLeaves = ![_serverId hasPrefix:@"_"];
}

- (void)setLatitude:(double)latitude
{
    NSAssert(latitude >= -90 && latitude <= 90, @"Invalid geofence latitude: %.f.", latitude);
    _latitude = latitude;
}

- (void)setLongitude:(double)longitude
{
    NSAssert(longitude >= -180 && longitude <= 180, @"Invalid geofence longitude: %f", longitude);
    _longitude = longitude;
}

- (void)setRadius:(double)radius
{
    if (radius > VisiGeofence.locationManager.geofenceMaximumRadius)
    {
        _radius = VisiGeofence.locationManager.geofenceMaximumRadius;
    }
    else
    {
        _radius = radius;
    }
}

- (BOOL)isLeaves
{
    return _isLeaves;
}

#pragma mark - public functions

NSString *visilabsBoolToString(BOOL boolVal)
{
    return boolVal ? @"true" : @"false";
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: [%@](%f,%f)~%f. Is inside: %@. Nodes:%@", self.title, self.serverId, self.latitude, self.longitude, self.radius, visilabsBoolToString(self.isInside), self.arrayNodes];
}

- (CLCircularRegion *)getGeoRegion
{
    return [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(self.latitude, self.longitude) radius:self.radius identifier:self.serverId];
}

- (BOOL)isEqualToCircleRegion:(CLCircularRegion *)geoRegion
{
    //region only compares by `identifier`.
    return ([self.serverId compare:geoRegion.identifier] == NSOrderedSame);
}

- (NSDictionary *)serializeGeofeneToDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"id"] = self.serverId;
    dict[@"latitude"] = @(self.latitude);
    dict[@"longitude"] = @(self.longitude);
    dict[@"radius"] = @(self.radius);
    dict[@"suid"] = NONULL(self.suid);
    dict[@"title"] = NONULL(self.title);
    dict[@"inside"] = @(self.isInside);
    dict[@"type"] = NONULL(self.type);
    dict[@"durationInSeconds"] = @(self.durationInSeconds);
    
    if (self.isLeaves)
    {
        NSAssert(self.arrayNodes.count == 0, @"Leave node should not have child.");
        return dict;
    }
    else
    {
        NSAssert(self.arrayNodes.count > 0, @"Inner node should have child.");
        NSMutableArray *arrayChild = [NSMutableArray array];
        for (VisilabsServerGeofence *childFence in self.arrayNodes)
        {
            [arrayChild addObject:[childFence serializeGeofeneToDict]];
        }
        dict[@"geofences"] = arrayChild;
        return dict;
    }
}

+ (VisilabsServerGeofence *)parseGeofenceFromDict:(NSDictionary *)dict
{
    NSAssert([dict isKindOfClass:[NSDictionary class]], @"Geofence dict invalid type: %@.", dict);
    if ([dict isKindOfClass:[NSDictionary class]])
    {
        BOOL isValidKey = (dict.allKeys.count >= 4 && [dict.allKeys containsObject:@"id"] && [dict.allKeys containsObject:@"latitude"] && [dict.allKeys containsObject:@"longitude"] && [dict.allKeys containsObject:@"radius"]);
        NSAssert(isValidKey, @"Geofence key format invalid: %@.", dict);
        if (isValidKey)
        {
            BOOL isValidValue = [dict[@"id"] isKindOfClass:[NSString class]] && [dict[@"latitude"] isKindOfClass:[NSNumber class]] && [dict[@"longitude"] isKindOfClass:[NSNumber class]] && [dict[@"radius"] isKindOfClass:[NSNumber class]];
            NSAssert(isValidValue, @"Geofence value format invalid: %@.", dict);
            if (isValidValue)
            {
                VisilabsServerGeofence *geofence = [[VisilabsServerGeofence alloc] init];
                geofence.serverId = dict[@"id"];
                geofence.latitude = [dict[@"latitude"] doubleValue];
                geofence.longitude = [dict[@"longitude"] doubleValue];
                geofence.radius = [dict[@"radius"] doubleValue];
                if ([dict.allKeys containsObject:@"suid"])
                {
                    geofence.suid = dict[@"suid"];
                }
                if ([dict.allKeys containsObject:@"title"])
                {
                    geofence.title = dict[@"title"];
                }
                if ([dict.allKeys containsObject:@"inside"])
                {
                    geofence.isInside = [dict[@"inside"] boolValue];
                }
                if ([dict.allKeys containsObject:@"type"])
                {
                    geofence.type = dict[@"type"];
                }
                if ([dict.allKeys containsObject:@"durationInSeconds"])
                {
                    geofence.durationInSeconds = [dict[@"durationInSeconds"] intValue];
                }
                
                BOOL hasGeofence = [dict.allKeys containsObject:@"geofences"] && ([dict[@"geofences"] isKindOfClass:[NSArray class]]) && (((NSArray *)dict[@"geofences"]).count > 0);
                if (geofence.isLeaves)
                {
                    NSAssert(!hasGeofence, @"Leave dict should not have child.");
                    return geofence;
                }
                else
                {
                    NSAssert(hasGeofence, @"Inner dict should have child.");
                    if (hasGeofence)
                    {
                        for (NSDictionary *dictChild in dict[@"geofences"])
                        {
                            VisilabsServerGeofence *childFence = [VisilabsServerGeofence parseGeofenceFromDict:dictChild];
                            if (childFence != nil)
                            {
                                childFence.parentFence = geofence;
                                [geofence.arrayNodes addObject:childFence];
                            }
                        }
                    }
                    NSAssert(geofence.arrayNodes.count > 0, @"Inner node have none child.");
                    return geofence;
                }
            }
        }
    }
    return nil;
}

+ (NSArray *)serializeToArrayDict:(NSArray *)parentFences
{
    NSMutableArray *array = [NSMutableArray array];
    for (VisilabsServerGeofence *parentFence in parentFences)
    {
        [array addObject:[parentFence serializeGeofeneToDict]];
    }
    return array;
}

+ (NSArray *)deserializeToArrayObj:(NSArray *)arrayDict
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in arrayDict)
    {
        [array addObject:[VisilabsServerGeofence parseGeofenceFromDict:dict]];
    }
    return array;
}

@end
