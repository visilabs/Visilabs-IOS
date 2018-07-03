//
//  VisilabsConfig.m
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsConfig.h"
#import "VisilabsParameter.h"

@implementation VisilabsConfig

static NSString *const kVERSION_NUMBER = @"2.5.17";

static NSString *const kLOGGER_URL = @"lgr.visilabs.net";
static NSString *const kREAL_TIME_URL = @"rt.visilabs.net";
static NSString *const kLOAD_BALANCE_PREFIX = @"NSC";
static NSString *const kOM_3_KEY = @"OM.3rd";

static NSString *const kTARGET_PREF_VOSS_STORE_KEY = @"OM.voss";
static NSString *const kTARGET_PREF_VCNAME_STORE_KEY = @"OM.vcname";
static NSString *const kTARGET_PREF_VCMEDIUM_STORE_KEY = @"OM.vcmedium";
static NSString *const kTARGET_PREF_VCSOURCE_STORE_KEY = @"OM.vcsource";
static NSString *const kTARGET_PREF_VSEG1_STORE_KEY = @"OM.vseg1";
static NSString *const kTARGET_PREF_VSEG2_STORE_KEY = @"OM.vseg2";
static NSString *const kTARGET_PREF_VSEG3_STORE_KEY = @"OM.vseg3";
static NSString *const kTARGET_PREF_VSEG4_STORE_KEY = @"OM.vseg4";
static NSString *const kTARGET_PREF_VSEG5_STORE_KEY = @"OM.vseg5";
static NSString *const kTARGET_PREF_BD_STORE_KEY = @"OM.bd";
static NSString *const kTARGET_PREF_GN_STORE_KEY = @"OM.gn";
static NSString *const kTARGET_PREF_LOC_STORE_KEY = @"OM.loc";
static NSString *const kTARGET_PREF_VPV_STORE_KEY = @"OM.vpv";
static NSString *const kTARGET_PREF_LPVS_STORE_KEY = @"OM.lpvs";
static NSString *const kTARGET_PREF_LPP_STORE_KEY = @"OM.lpp";
static NSString *const kTARGET_PREF_VQ_STORE_KEY = @"OM.vq";
static NSString *const kTARGET_PREF_VRDOMAIN_STORE_KEY = @"OM.vrDomain";

static NSString *const kTARGET_PREF_VOSS_KEY = @"OM.OSS";
static NSString *const kTARGET_PREF_VCNAME_KEY = @"OM.cname";
static NSString *const kTARGET_PREF_VCMEDIUM_KEY = @"OM.cmedium";
static NSString *const kTARGET_PREF_VCSOURCE_KEY = @"OM.csource";
static NSString *const kTARGET_PREF_VSEG1_KEY = @"OM.vseg1";
static NSString *const kTARGET_PREF_VSEG2_KEY = @"OM.vseg2";
static NSString *const kTARGET_PREF_VSEG3_KEY = @"OM.vseg3";
static NSString *const kTARGET_PREF_VSEG4_KEY = @"OM.vseg4";
static NSString *const kTARGET_PREF_VSEG5_KEY = @"OM.vseg5";
static NSString *const kTARGET_PREF_BD_KEY = @"OM.bd";
static NSString *const kTARGET_PREF_GN_KEY = @"OM.gn";
static NSString *const kTARGET_PREF_LOC_KEY = @"OM.loc";
static NSString *const kTARGET_PREF_VPV_KEY = @"OM.pv";
static NSString *const kTARGET_PREF_LPVS_KEY = @"OM.pv";
static NSString *const kTARGET_PREF_LPP_KEY = @"OM.pp";
static NSString *const kTARGET_PREF_VQ_KEY = @"OM.q";
static NSString *const kTARGET_PREF_VRDOMAIN_KEY = @"OM.rDomain";

static NSString *const kTARGET_PREF_PPR_KEY = @"OM.ppr";

static NSMutableArray *_visilabsParameters;

static NSString *const kORGANIZATIONID_KEY = @"OM.oid";
static NSString *const kSITEID_KEY = @"OM.siteID";
static NSString *const kCOOKIEID_KEY = @"OM.cookieID";
static NSString *const kEXVISITORID_KEY = @"OM.exVisitorID";

static NSString *const kTOKENID_KEY = @"OM.sys.TokenID";
static NSString *const kAPPID_KEY = @"OM.sys.AppID";

static NSString *const kLATITUDE_KEY = @"OM.latitude";
static NSString *const kLONGITUDE_KEY = @"OM.longitude";


static NSString *const kZONE_ID_KEY = @"OM.zid";
static NSString *const kBODY_KEY = @"OM.body";

static NSString *const kACT_ID_KEY = @"actid";
static NSString *const kACT_KEY = @"act";

static NSString *const kFILTER_KEY = @"OM.w.f";
static NSString *const kAPIVER_KEY = @"OM.apiver";


static NSString *const kGEO_ID_KEY = @"OM.locationid";

static NSString *const kTRIGGER_EVENT_KEY = @"OM.triggerevent";


+(NSString *) LOGGER_URL
{
    return kLOGGER_URL;
}

+(NSString *) REAL_TIME_URL
{
    return kREAL_TIME_URL;
}

+(NSString *) LOAD_BALANCE_PREFIX
{
    return kLOAD_BALANCE_PREFIX;
}

+(NSString *) OM_3_KEY
{
    return kOM_3_KEY;
}




+(NSString *) ORGANIZATIONID_KEY
{
    return kORGANIZATIONID_KEY;
}

+(NSString *) SITEID_KEY
{
    return kSITEID_KEY;
}

+(NSString *) COOKIEID_KEY
{
    return kCOOKIEID_KEY;
}

+(NSString *) EXVISITORID_KEY
{
    return kEXVISITORID_KEY;
}

+(NSString *) TOKENID_KEY
{
    return kTOKENID_KEY;
}

+(NSString *) APPID_KEY
{
    return kAPPID_KEY;
}


+(NSString *) ZONE_ID_KEY
{
    return kZONE_ID_KEY;
}

+(NSString *) BODY_KEY
{
    return kBODY_KEY;
}

+(NSString *) ACT_ID_KEY
{
    return kACT_ID_KEY;
}

+(NSString *) ACT_KEY
{
    return kACT_KEY;
}

+(NSString *) FILTER_KEY
{
    return kFILTER_KEY;
}

+(NSString *) APIVER_KEY
{
    return kAPIVER_KEY;
}

+(NSString *) LATITUDE_KEY
{
    return kLATITUDE_KEY;
}

+(NSString *) LONGITUDE_KEY
{
    return kLONGITUDE_KEY;
}

+(NSString *) GEO_ID_KEY
{
    return kGEO_ID_KEY;
}

+(NSString *) TRIGGER_EVENT_KEY
{
    return kTRIGGER_EVENT_KEY;
}

+ (NSArray *)visilabsParameters
        {
    if(_visilabsParameters == nil)
    {
        _visilabsParameters = [[NSMutableArray alloc] init];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VOSS_KEY storeKey:kTARGET_PREF_VOSS_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VCNAME_KEY storeKey:kTARGET_PREF_VCNAME_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VCMEDIUM_KEY storeKey:kTARGET_PREF_VCMEDIUM_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VCSOURCE_KEY storeKey:kTARGET_PREF_VCSOURCE_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VSEG1_KEY storeKey:kTARGET_PREF_VSEG1_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VSEG2_KEY storeKey:kTARGET_PREF_VSEG2_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VSEG3_KEY storeKey:kTARGET_PREF_VSEG3_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VSEG4_KEY storeKey:kTARGET_PREF_VSEG4_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VSEG5_KEY storeKey:kTARGET_PREF_VSEG5_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_BD_KEY storeKey:kTARGET_PREF_BD_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_GN_KEY storeKey:kTARGET_PREF_GN_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_LOC_KEY storeKey:kTARGET_PREF_LOC_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VPV_KEY storeKey:kTARGET_PREF_VPV_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_LPVS_KEY storeKey:kTARGET_PREF_LPVS_STORE_KEY count:[NSNumber numberWithInteger:10] relatedKeys:[NSArray arrayWithObjects:kTARGET_PREF_PPR_KEY, nil]]];
        
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_LPP_KEY storeKey:kTARGET_PREF_LPP_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VQ_KEY storeKey:kTARGET_PREF_VQ_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        [_visilabsParameters addObject:[[VisilabsParameter alloc] initWithKey:kTARGET_PREF_VRDOMAIN_KEY storeKey:kTARGET_PREF_VRDOMAIN_STORE_KEY count:[NSNumber numberWithInteger:1] relatedKeys:nil]];
        
    }
    return [_visilabsParameters copy];
}
@end
