//
//  EMURLSessionDelegate.h
//  EuroPush
//
//  Created by Ozan Uysal on 21/03/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EMURLSessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, copy) id responseBlock;

@end
