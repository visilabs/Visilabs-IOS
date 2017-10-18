@interface UIImage (VisilabsImageEffects)

- (UIImage *)visilabs_applyLightEffect;
- (UIImage *)visilabs_applyExtraLightEffect;
- (UIImage *)visilabs_applyDarkEffect;
- (UIImage *)visilabs_applyTintEffectWithColor:(UIColor *)tintColor;

- (UIImage *)visilabs_applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;
@end
