#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (VisilabsHelpers)

- (UIImage *)visilabs_snapshotImage;
- (UIImage *)visilabs_snapshotForBlur;
- (int)visilabs_fingerprintVersion;

@end

