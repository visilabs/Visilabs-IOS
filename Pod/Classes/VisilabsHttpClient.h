//
//  VisilabsHttpClient.h
//  Visilabs-IOS
//
//  Created by Visilabs on 8.12.2015.
//  Copyright © 2015 Visilabs. All rights reserved.
//

#import "VisilabsAction.h"

@interface VisilabsHttpClient : NSObject

- (void)sendRequest:(VisilabsAction *)visilabsAction
         AndSuccess:(void (^)(VisilabsResponse *success))sucornil
         AndFailure:(void (^)(VisilabsResponse *failed))failornil;

@end
