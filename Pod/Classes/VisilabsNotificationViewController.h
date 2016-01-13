#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "VisilabsNotification.h"

@protocol VisilabsNotificationViewControllerDelegate;


@interface VisilabsNotificationViewController : UIViewController

@property (nonatomic, strong) VisilabsNotification *notification;
@property (nonatomic, weak) id<VisilabsNotificationViewControllerDelegate> delegate;

- (void)hideWithAnimation:(BOOL)animated completion:(void (^)(void))completion;

@end

@interface VisilabsFullNotificationViewController : VisilabsNotificationViewController

@property (nonatomic, strong) UIImage *backgroundImage;

@end

@interface VisilabsMiniNotificationViewController : VisilabsNotificationViewController

@property (nonatomic, strong) UIColor *backgroundColor;

- (void)showWithAnimation;

@end


@protocol VisilabsNotificationViewControllerDelegate <NSObject>

- (void)notificationController:(VisilabsNotificationViewController *)controller wasDismissedWithStatus:(BOOL)status;

@end