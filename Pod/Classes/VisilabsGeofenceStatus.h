//
//  VisilabsGeofenceStatus.h
//  Pods
//
//  Created by Visilabs on 15.08.2016.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

/**
 The object to handle geofence status inside SHAppStatus.
 */
@interface VisilabsGeofenceStatus : NSObject

/**
 Singleton for get app status instance.
 */
+ (VisilabsGeofenceStatus *)sharedInstance;

/**
 Match to `app_status` dictionary's `geofences`. It's a time stamp of server provided geofence list. If the time stamp is newer than client fetch time, client should fetch geofence list again and monitor new list; if the time stamp is NULL or empty, client should clear cached geofence and stop monitor.
 */
@property (nonatomic, strong) NSString *geofenceTimestamp;

@property (nonatomic, strong) NSArray *arrayGeofenceFetchList;

@end


/**
 An object to represend server fetch geofence region. It's two levels: parent fence and child fence.
 */
@interface VisilabsServerGeofence : NSObject

/**
 Id from server for this fence. It will be used as `identifier` in `CLCircularRegion` so it must be not duplicated.
 */
@property (nonatomic, strong) NSString *serverId;

/**
 Latitude of this fence.
 */
@property (nonatomic) double latitude;

/**
 Longitude of this fence.
 */
@property (nonatomic) double longitude;

/**
 Radius of this fence. It will be adjust to not exceed `maximumRegionMonitoringDistance`.
 */
@property (nonatomic) double radius;

/**
 Internal unique id for object. Optional for leaf geofence, none for inner node.
 */
@property (nonatomic, strong) NSString *suid;

/**
 Web console input the title name for this latitude/longitude. Optional for leaf geofence, none for inner node.
 */
@property (nonatomic, strong) NSString *title;

/**
 Whether device is inside this geofence.
 */
@property (nonatomic) BOOL isInside;

/**
 A weak reference to its parent fence.
 */
@property (nonatomic, weak) VisilabsServerGeofence *parentFence;

/**
 Child nodes for parent fence. For child fence it's definity nil; for parent fence it would be nil.
 */
@property (nonatomic, strong) NSMutableArray *arrayNodes;

/**
 Whether this is actual geofence. Only actual geofence should send logline to server. Inner nodes's `id` starts with "_", actual geofence's `id` is "<id>-<distance>".
 */
@property (nonatomic, readonly) BOOL isLeaves;

/**
 Use this geofence data to create monitoring region.
 */
- (CLCircularRegion *)getGeoRegion;

/**
 Serialize self into a dictionary. Vice verse against `+ (VisilabsServerGeofence *)parseGeofenceFromDict:(NSDictionary *)dict;`.
 */
- (NSDictionary *)serializeGeofeneToDict;

/**
 Compare function.
 */
- (BOOL)isEqualToCircleRegion:(CLCircularRegion *)geoRegion;

/**
 Parse an object from dictionary. If parse fail return nil.
 @param dict The dictionary information.
 @return If successfully parse return the object; otherwise return nil.
 */
+ (VisilabsServerGeofence *)parseGeofenceFromDict:(NSDictionary *)dict;

/**
 Make this object array to string array for store to NSUserDefaults.
 */
+ (NSArray *)serializeToArrayDict:(NSArray *)parentFences;

/**
 When read from NSUserDefaults, parse back to object array.
 */
+ (NSArray *)deserializeToArrayObj:(NSArray *)arrayDict;


@property (nonatomic, strong) NSString *type;

@property (nonatomic) int durationInSeconds;

@end