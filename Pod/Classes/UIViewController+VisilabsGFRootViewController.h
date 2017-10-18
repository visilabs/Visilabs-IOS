//
//  UIViewController+VisilabsGFRootViewController.h
//  Pods
//
//  Created by Visilabs on 4.08.2016.
//
//

#import <UIKit/UIKit.h>

/*!
 UIViewController categroy.
 
 @since 2.0.0.0
 */
@interface UIViewController (VisilabsGFRootViewController)

/*!
 Method to get the applications root view controller, this is used in several modules when presneting alert views/internal banners.
 
 @return the current root view controller of the application
 
 @since 2.0.0.0
 */
+ (UIViewController *)applicationRootViewController;

@end

