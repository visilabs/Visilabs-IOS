//
//  UIViewController+VisilabsGFRootViewController.m
//  Pods
//
//  Created by Visilabs on 4.08.2016.
//
//

#if !__has_feature(objc_arc)
#error Donky SDK must be built with ARC.
// You can turn on ARC for only Donky Class files by adding -fobjc-arc to the build phase for each of its files.
#endif

#import "UIViewController+VisilabsGFRootViewController.h"
//#import "DNDonkyCore.h"
//#import "DNLoggingController.h"

@implementation UIViewController (VisilabsGFRootViewController)

+ (UIViewController *)applicationRootViewController
{
    @try {
        
        return nil;
        /*
        UIViewController *topViewController = [[[DNDonkyCore sharedInstance] applicationWindow] rootViewController] ? : [[[UIApplication sharedApplication] delegate] window].rootViewController;
        
        while (topViewController.presentedViewController) {
            topViewController = [topViewController presentedViewController];
        }
        
        if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *) topViewController;
            topViewController = [tab selectedViewController];
        }
        
        return topViewController;
         */
    }
    @catch (NSException *exception) {
        //DNErrorLog(@"FATAl Exception when trying to get the application root window: %@\n This may be beause your app delegate does not have a root window, if so then please set the applicationWindow property on DNDonkyCore to your applications root window.", [exception description]);
        //[DNLoggingController submitLogToDonkyNetworkSuccess:nil failure:nil];
    }
    
    return nil;
}


@end
