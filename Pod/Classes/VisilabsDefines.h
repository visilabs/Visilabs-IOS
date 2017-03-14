//
//  VisilabsDefines.h
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import <Foundation/Foundation.h>

// cater for debug/release mode of logging
#ifdef VISILABSDEBUG
#define DLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#else
#define DLog(...) /* */
#endif


#define SHErrorDomain  @"SHErrorDomain"

/**
 Make sure not pass nil or NSNull, this is useful to avoid insert nil to NSArray and cause crash.
 */
#define NONULL(str)     ((str && str != (id)[NSNull null]) ? (str) : @"")

#define REGULAR_HEARTBEAT_LOGTIME       @"REGULAR_HEARTBEAT_LOGTIME"
#define REGULAR_LOCATION_LOGTIME        @"REGULAR_LOCATION_LOGTIME"

//NSUserDefaults value for passing value between modules. It's not used as local cache for location, and before use it must have notification "SH_LMBridge_UpdateGeoLocation" to update the value.
#define SH_GEOLOCATION_LAT      @"SH_GEOLOCATION_LAT"
#define SH_GEOLOCATION_LNG      @"SH_GEOLOCATION_LNG"

/*
//For get Beacon module's bluetooth status, before use it must have notification "SH_LMBridge_UpdateBluetoothStatus" to update the value.
#define SH_BEACON_BLUETOOTH     @"SH_BEACON_BLUETOOTH"
//For get Beacon module's iBeacon support status, before use it must have notification "SH_LMBridge_UpdateiBeaconStatus" to update the value.
#define SH_BEACON_iBEACON       @"SH_BEACON_iBEACON"
//For get location permission status, before use it must have notification "SH_LMBridge_UpdateLocationPermissionStatus" to update the value.
*/


#define SH_LOCATION_STATUS      @"SH_LOCATION_STATUS"

typedef void (^VisilabsCallbackHandler)(NSObject *result, NSError *error);

/*
NSString *visilabsSerializeObjToJson(NSObject *obj)
{
    if (obj == nil)
    {
        return @"";
    }
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];
    assert((error == nil) && "Fail to serialize object.");
    if (error == nil)
    {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else
    {
        return nil;
    }
}
*/
