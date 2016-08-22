//
//  BaseRequest.m
//  PigeoniOSSDK
//
//  Created by Ozan Uysal on 12/08/14.
//  Copyright (c) 2014 Appcent. All rights reserved.
//

#import "EMRegisterRequest.h"

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIKit.h>

#import <sys/utsname.h>

@implementation EMRegisterRequest

-(id) init {
    
    if(self = [super init]) {
        CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
        CTCarrier *ct = [netInfo subscriberCellularProvider];
        NSString *carrier = ct.mobileCountryCode ? [NSString stringWithFormat:@"%@%@", ct.mobileCountryCode, ct.mobileNetworkCode] : @"";
        // get hardware code
        struct utsname systemInfo;
        uname(&systemInfo);
        UIDevice *device = [UIDevice currentDevice];
        
        // get device params
        self.carrier = carrier;
        self.deviceType = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        self.os = device.systemName;
        self.osVersion = device.systemVersion;
        self.deviceName = device.name;
        self.local = [[NSLocale preferredLanguages] objectAtIndex:0];
        self.firstTime = [NSNumber numberWithInt:1];
        if (NSClassFromString(@"ASIdentifierManager")) {
            //self.advertisingIdentifier = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        }
        self.identifierForVendor = [UIDevice currentDevice].identifierForVendor.UUIDString;
        
        self.extra = [NSMutableDictionary new];
        
    }
    return self;
}

- (NSString *) getPath {
    return @"subscription";
}

- (NSString *) getPort {
    return @"4243";
}

- (NSString *) getMethod {
    return @"POST";
}

- (NSString *) getSubdomain {
    return @"pushs";
}

@end
