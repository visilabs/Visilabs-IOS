#import <UIKit/UIKit.h>

@interface UIColor (VisilabsColor)

+ (UIColor *)visilabs_applicationPrimaryColor;
+ (UIColor *)visilabs_lightEffectColor;
+ (UIColor *)visilabs_extraLightEffectColor;
+ (UIColor *)visilabs_darkEffectColor;

- (UIColor *)colorWithSaturationComponent:(CGFloat) saturation;

@end
