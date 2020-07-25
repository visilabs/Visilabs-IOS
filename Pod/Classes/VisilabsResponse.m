//
//  VisilabsResponse.m
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsResponse.h"
#import "VisilabsJSON.h"

@implementation VisilabsResponse

- (void)parseResponseString:(NSString *)res {
    self.parsedResponse = [res objectFromJSONString];
}

- (void)parseResponseData:(NSData *)dat {
    self.parsedResponse = [dat objectFromJSONData];
    self.responseArray = [dat objectFromJSONData];
    
    if(self.parsedResponse && self.targetRequestType == VisilabsTargetRequestTypeFavorite)
    {
        self.favoriteAttributeActions = [self.parsedResponse objectForKey:@"FavoriteAttributeAction"];    
    }
    
    
}

@end
