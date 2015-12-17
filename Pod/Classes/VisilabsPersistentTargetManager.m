//
//  VisilabsPersistentTargetManager.m
//  Visilabs-IOS
//
//  Created by Visilabs on 9.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsPersistentTargetManager.h"

@implementation VisilabsPersistentTargetManager

+(void) saveParameters:(NSDictionary*) parameters
{
    @synchronized (self) {
        if(!parameters){
            return;
        }
        
        NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
        NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
        
        for (VisilabsParameter *visilabsParameter in [VisilabsConfig visilabsParameters])
        {
            NSString *key = visilabsParameter.key;
            NSString *storeKey = visilabsParameter.storeKey;
            NSArray *relatedKeys = visilabsParameter.relatedKeys;
            NSNumber *count = visilabsParameter.count;
            
            NSString *parameterValue = [parameters objectForKey:key];
            
            if(parameterValue && [parameterValue length] > 0)
            {
                if([count intValue] == 1)
                {
                    if(relatedKeys != nil && [relatedKeys count] > 0)
                    {
                        NSString *parameterValueToStore = [parameterValue copy];
                        NSString *relatedKey = [relatedKeys objectAtIndex:0];
                        if([parameters objectForKey:relatedKey])
                        {
                            NSString *relatedKeyValue = [[parameters objectForKey:relatedKey] stringByTrimmingCharactersInSet:
                                                         [NSCharacterSet whitespaceCharacterSet]];
                            parameterValueToStore = [parameterValueToStore stringByAppendingString:@"|"];
                            parameterValueToStore = [parameterValueToStore stringByAppendingString:relatedKeyValue];
                        }
                        else
                        {
                            parameterValueToStore = [parameterValueToStore stringByAppendingString:@"|0"];
                        }
                        parameterValueToStore = [parameterValueToStore stringByAppendingString:dateString];
                        [VisilabsDataManager save:storeKey withObject:parameterValueToStore];
                    }
                    else
                    {
                        [VisilabsDataManager save:storeKey withObject:parameterValue];
                    }
                }
                else if([count intValue] > 1)
                {
                    NSString *previousParameterValue = (NSString *)[VisilabsDataManager read:storeKey];
                    NSString *parameterValueToStore  = [parameterValue stringByAppendingString:@"|"];
                    parameterValueToStore  = [parameterValueToStore stringByAppendingString:dateString];
                    if(previousParameterValue && [previousParameterValue length] > 0)
                    {
                        NSArray *previousParameterValueParts = [previousParameterValue componentsSeparatedByString:@"~"];
                        if(previousParameterValueParts)
                        {
                            for (int i = 0; i< [previousParameterValueParts count]; i++) {
                                if(i==9)
                                {
                                    break;
                                }
                                NSString *decodedPreviousParameterValuePart = [previousParameterValueParts objectAtIndex:i];
                                //TODO:burayı kontrol et java'da "\\|" yapmak gerekiyordu.
                                NSArray *decodedPreviousParameterValuePartArray = [decodedPreviousParameterValuePart componentsSeparatedByString:@"|"];
                                if([decodedPreviousParameterValuePartArray count] == 2)
                                {
                                    parameterValueToStore = [parameterValueToStore stringByAppendingString:@"~"];
                                    parameterValueToStore = [parameterValueToStore stringByAppendingString:decodedPreviousParameterValuePart];
                                }
                            }
                        }
                    }
                    [VisilabsDataManager save:storeKey withObject:parameterValueToStore];
                }
            }
        }
    }
}

+(NSDictionary*) getParameters
{
    NSMutableDictionary * parameters = [[NSMutableDictionary alloc] init];
    for (VisilabsParameter *visilabsParameter in [VisilabsConfig visilabsParameters])
    {
        NSString *storeKey = visilabsParameter.storeKey;
        NSString *value = (NSString *)[VisilabsDataManager read:storeKey];
        if(value != nil && [value length] > 0)
        {
            [parameters setObject:value forKey:storeKey];
        }
    }
    return [parameters copy];
}

+(void) clearParameters
{
    for (VisilabsParameter *visilabsParameter in [VisilabsConfig visilabsParameters])
    {
        [VisilabsDataManager remove:visilabsParameter.storeKey];
    }
}

@end
