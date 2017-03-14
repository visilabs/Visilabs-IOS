//
//  EMURLSessionDelegate.m
//  EuroPush
//
//  Created by Ozan Uysal on 21/03/15.
//  Copyright (c) 2015 Appcent. All rights reserved.
//

#import "EMURLSessionDelegate.h"

#import <UIKit/UIKit.h>
#import "EMLogging.h"

@implementation EMURLSessionDelegate

@synthesize responseBlock;

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    LogInfo(@"URLSession Error : %@ in task : %@",error,task.originalRequest);
    if(self.responseBlock) {
        // retention report fail
        ((void (^)(UIBackgroundFetchResult))self.responseBlock)(UIBackgroundFetchResultFailed);
        self.responseBlock = nil;
    }
}

-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    LogInfo(@"URLSessionDidFinishEventsForBackgroundURLSession : %@",session);
    if(self.responseBlock) {
        ((void (^)(UIBackgroundFetchResult))self.responseBlock)(UIBackgroundFetchResultNewData);
        self.responseBlock = nil;
    }
}

- (void) URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    LogInfo(@"URLSession didFinishDownloadingToURL : %@",location);
    if(self.responseBlock) {
        ((void (^)(UIBackgroundFetchResult))self.responseBlock)(UIBackgroundFetchResultNewData);
        self.responseBlock = nil;
    }
}



@end
