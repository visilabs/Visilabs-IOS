#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import "UIView+VisilabsHelpers.h"
#import "VisilabsDefines.h"
#import "VisilabsNotification.h"
#import "VisilabsNotificationViewController.h"
#import "UIColor+VisilabsColor.h"
#import "UIImage+VisilabsAverageColor.h"
#import "UIImage+VisilabsImageEffects.h"

#define VisilabsNotificationHeight 65.0f




@interface VisilabsCircleLayer : CALayer {}

@property (nonatomic, assign) CGFloat circlePadding;

@end

@interface VisilabsElasticEaseOutAnimation : CAKeyframeAnimation {}

- (instancetype)initWithStartValue:(CGRect)start endValue:(CGRect)end andDuration:(double)duration;

@end

@interface VisilabsGradientMaskLayer : CAGradientLayer {}

@end

@interface VisilabsAlphaMaskView : UIView {
    
@protected
    CAGradientLayer *_maskLayer;
}

@end

@interface VisilabsBgRadialGradientView : UIView

@end

@interface VisilabsActionButton : UIButton

@end

@interface VisilabsNotificationViewController ()

@end

@implementation VisilabsNotificationViewController

- (void)hideWithAnimation:(BOOL)animated completion:(void (^)(void))completion
{
    return;
}

@end

@interface VisilabsFullNotificationViewController () {
    CGPoint _viewStart;
    BOOL _touching;
}

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *titleView;
@property (strong, nonatomic) IBOutlet UILabel *bodyView;
@property (strong, nonatomic) IBOutlet UIButton *okayButton;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UIView *imageDragView;


@end

@interface VisilabsFullNotificationViewController ()

@end

@implementation VisilabsFullNotificationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.notification) {
        if (self.notification.image) {
            UIImage *image = [UIImage imageWithData:self.notification.image scale:2.0f];
            if (image) {
                self.imageView.image = image;
            } else {
                DLog(@"image failed to load from data: %@", self.notification.image);
            }
        }
        
        self.titleView.text = self.notification.title;
        self.bodyView.text = self.notification.body;
        
        if (self.notification.buttonText && [self.notification.buttonText length] > 0) {
            [self.okayButton setTitle:self.notification.buttonText forState:UIControlStateNormal];
            [self.okayButton sizeToFit];
        }
    }
    
    self.backgroundImageView.image = self.backgroundImage;
    
    self.imageView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.imageView.layer.shadowOpacity = 1.0f;
    self.imageView.layer.shadowRadius = 5.0f;
    self.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
}

- (void)hideWithAnimation:(BOOL)animated completion:(void (^)(void))completion
{
    [self.presentingViewController dismissViewControllerAnimated:animated completion:completion];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.okayButton.center = CGPointMake(CGRectGetMidX(self.okayButton.superview.bounds), self.okayButton.center.y);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}
#endif

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskAll;
}

- (IBAction)pressedOkay
{
    id<VisilabsNotificationViewControllerDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(notificationController:wasDismissedWithStatus:)]) {
        [delegate notificationController:self wasDismissedWithStatus:YES];
    }
}

- (IBAction)pressedClose
{
    id<VisilabsNotificationViewControllerDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(notificationController:wasDismissedWithStatus:)]) {
        [delegate notificationController:self wasDismissedWithStatus:NO];
    }
}

- (IBAction)didPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.numberOfTouches == 1) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            _viewStart = self.imageView.layer.position;
            _touching = YES;
        } else if (gesture.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [gesture translationInView:self.view];
            self.imageView.layer.position = CGPointMake(0.3f * (translation.x) + _viewStart.x, 0.3f * (translation.y) + _viewStart.y);
        }
    }
    
    if (_touching && (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled)) {
        _touching = NO;
        CGPoint viewEnd = self.imageView.layer.position;
        CGPoint viewDistance = CGPointMake(viewEnd.x - _viewStart.x, viewEnd.y - _viewStart.y);
        CGFloat distance = (CGFloat)sqrt(viewDistance.x * viewDistance.x + viewDistance.y * viewDistance.y);
        [UIView animateWithDuration:(distance / 500.0f) delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.imageView.layer.position = self->_viewStart;
        } completion:nil];
    }
}

@end

@interface VisilabsMiniNotificationViewController () {
    CGPoint _panStartPoint;
    CGPoint _position;
    BOOL _canPan;
    BOOL _isBeingDismissed;
}

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) VisilabsCircleLayer *VisilabsCircleLayer;
@property (nonatomic, strong) UILabel *bodyLabel;

@end

@implementation VisilabsMiniNotificationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _canPan = YES;
    _isBeingDismissed = NO;
    self.view.clipsToBounds = YES;
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.imageView.layer.masksToBounds = YES;
    
    self.bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.bodyLabel.textColor = [UIColor whiteColor];
    self.bodyLabel.backgroundColor = [UIColor clearColor];
    self.bodyLabel.font = [UIFont systemFontOfSize:14.0f];
    self.bodyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.bodyLabel.numberOfLines = 0;
    
    if (!self.backgroundColor) {
        self.backgroundColor = [UIColor visilabs_applicationPrimaryColor];
        if (!self.backgroundColor) {
            self.backgroundColor = [UIColor visilabs_darkEffectColor];
        }
    }
    
    UIColor *backgroundColorWithAlphaComponent = [self.backgroundColor colorWithAlphaComponent:0.95f];
    self.view.backgroundColor = backgroundColorWithAlphaComponent;
    
    if (self.notification != nil) {
        if (self.notification.image != nil) {
            self.imageView.image = [UIImage imageWithData:self.notification.image scale:2.0f];
            self.imageView.hidden = NO;
        } else {
            self.imageView.hidden = YES;
        }
        
        if (self.notification.body != nil) {
            self.bodyLabel.text = self.notification.body;
            self.bodyLabel.hidden = NO;
        } else {
            self.bodyLabel.hidden = YES;
        }
    }
    
    self.VisilabsCircleLayer = [VisilabsCircleLayer layer];
    self.VisilabsCircleLayer.contentsScale = [UIScreen mainScreen].scale;
    [self.VisilabsCircleLayer setNeedsDisplay];
    
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.bodyLabel];
    [self.view.layer addSublayer:self.VisilabsCircleLayer];
    
    self.view.frame = CGRectMake(0.0f, 0.0f, 0.0f, 30.0f);
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    gesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:gesture];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.view addGestureRecognizer:pan];
}

- (void)viewWillLayoutSubviews
{
    UIView *parentView = self.view.superview;
    CGRect parentFrame;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000
    parentFrame = parentView.frame;
#elif __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([self respondsToSelector:@selector(viewWillTransitionToSize:withTransitionCoordinator:)]) {
        parentFrame = parentView.frame;
    } else {
        double angle = [self angleForInterfaceOrientation:[self interfaceOrientation]];
        parentFrame = CGRectApplyAffineTransform(parentView.frame, CGAffineTransformMakeRotation((float)angle));
    }
#else
    double angle = [self angleForInterfaceOrientation:[self interfaceOrientation]];
    parentFrame = CGRectApplyAffineTransform(parentView.frame, CGAffineTransformMakeRotation((float)angle));
#endif
    
    self.view.frame = CGRectMake(0.0f, parentFrame.size.height - VisilabsNotificationHeight, parentFrame.size.width, VisilabsNotificationHeight * 3.0f);
    
    // Position images
    self.imageView.layer.position = CGPointMake(VisilabsNotificationHeight / 2.0f, VisilabsNotificationHeight / 2.0f);
    
    // Position circle around image
    self.VisilabsCircleLayer.position = self.imageView.layer.position;
    [self.VisilabsCircleLayer setNeedsDisplay];
    
    // Position body label
    CGSize constraintSize = CGSizeMake(self.view.frame.size.width - VisilabsNotificationHeight - 12.5f, CGFLOAT_MAX);
    CGSize sizeToFit;
    // Use boundingRectWithSize for iOS 7 and above, sizeWithFont otherwise.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        sizeToFit = [self.bodyLabel.text boundingRectWithSize:constraintSize
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{NSFontAttributeName: self.bodyLabel.font}
                                                      context:nil].size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        
        sizeToFit = [self.bodyLabel.text sizeWithFont:self.bodyLabel.font
                                    constrainedToSize:constraintSize
                                        lineBreakMode:self.bodyLabel.lineBreakMode];
        
#pragma clang diagnostic pop
    }
#else
    sizeToFit = [self.bodyLabel.text sizeWithFont:self.bodyLabel.font
                                constrainedToSize:constraintSize
                                    lineBreakMode:self.bodyLabel.lineBreakMode];
#endif
    
    self.bodyLabel.frame = CGRectMake(VisilabsNotificationHeight, (CGFloat)ceil((VisilabsNotificationHeight - sizeToFit.height) / 2.0f) - 2.0f, (CGFloat)ceil(sizeToFit.width), (CGFloat)ceil(sizeToFit.height));
}

- (UIView *)getTopView
{
    UIView *topView = nil;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if(window) {
        for (UIView *subview in window.subviews) {
            if (!subview.hidden && subview.alpha > 0 && subview.frame.size.width > 0 && subview.frame.size.height > 0) {
                topView = subview;
            }
        }
    }
    return topView;
}

- (double)angleForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            return -M_PI_2;
        case UIInterfaceOrientationLandscapeRight:
            return M_PI_2;
        case UIInterfaceOrientationPortraitUpsideDown:
            return M_PI;
        default:
            return 0.0;
    }
}

- (void)showWithAnimation
{
    [self.view removeFromSuperview];
    
    UIView *topView = [self getTopView];
    if (topView) {
        
        CGRect topFrame;
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000
        topFrame = topView.frame;
#elif __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([self respondsToSelector:@selector(viewWillTransitionToSize:withTransitionCoordinator:)]) {
            topFrame = topView.frame;
        } else {
            double angle = [self angleForInterfaceOrientation:[self interfaceOrientation]];
            topFrame = CGRectApplyAffineTransform(topView.frame, CGAffineTransformMakeRotation((float)angle));
        }
#else
        double angle = [self angleForInterfaceOrientation:[self interfaceOrientation]];
        topFrame = CGRectApplyAffineTransform(topView.frame, CGAffineTransformMakeRotation((float)angle));
#endif
        
        [topView addSubview:self.view];
        
        _canPan = NO;
        
        self.view.frame = CGRectMake(0.0f, topFrame.size.height, topFrame.size.width, VisilabsNotificationHeight * 3.0f);
        _position = self.view.layer.position;
        
        [UIView animateWithDuration:0.1f animations:^{
            self.view.frame = CGRectMake(0.0f, topFrame.size.height - VisilabsNotificationHeight, topFrame.size.width, VisilabsNotificationHeight * 3.0f);
        } completion:^(BOOL finished) {
            self->_position = self.view.layer.position;
            [self performSelector:@selector(animateImage) withObject:nil afterDelay:0.1];
            self->_canPan = YES;
        }];
    }
}

- (void)animateImage
{
    CGSize imageViewSize = CGSizeMake(40.0f, 40.0f);
    CGFloat duration = 0.5f;
    
    // Animate the circle around the image
    CGRect before = _VisilabsCircleLayer.bounds;
    CGRect after = CGRectMake(0.0f, 0.0f, imageViewSize.width + (_VisilabsCircleLayer.circlePadding * 2.0f), imageViewSize.height + (_VisilabsCircleLayer.circlePadding * 2.0f));
    
    VisilabsElasticEaseOutAnimation *circleAnimation = [[VisilabsElasticEaseOutAnimation alloc] initWithStartValue:before endValue:after andDuration:duration];
    _VisilabsCircleLayer.bounds = after;
    [_VisilabsCircleLayer addAnimation:circleAnimation forKey:@"bounds"];
    
    // Animate the image
    before = _imageView.bounds;
    after = CGRectMake(0.0f, 0.0f, imageViewSize.width, imageViewSize.height);
    VisilabsElasticEaseOutAnimation *imageAnimation = [[VisilabsElasticEaseOutAnimation alloc] initWithStartValue:before endValue:after andDuration:duration];
    _imageView.layer.bounds = after;
    [_imageView.layer addAnimation:imageAnimation forKey:@"bounds"];
}

- (void)hideWithAnimation:(BOOL)animated completion:(void (^)(void))completion
{
    _canPan = NO;
    
    if (!_isBeingDismissed) {
        _isBeingDismissed = YES;
        
        CGFloat duration;
        
        if (animated) {
            duration = 0.5f;
        } else {
            duration = 0.0f;
        }
        
        UIView *parentView = self.view.superview;
        CGRect parentFrame;
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000
        parentFrame = parentView.frame;
#elif __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([self respondsToSelector:@selector(viewWillTransitionToSize:withTransitionCoordinator:)]) {
            parentFrame = parentView.frame;
        } else {
            double angle = [self angleForInterfaceOrientation:[self interfaceOrientation]];
            parentFrame = CGRectApplyAffineTransform(parentView.frame, CGAffineTransformMakeRotation((float)angle));
        }
#else
        double angle = [self angleForInterfaceOrientation:[self interfaceOrientation]];
        parentFrame = CGRectApplyAffineTransform(parentView.frame, CGAffineTransformMakeRotation((float)angle));
#endif
        
        [UIView animateWithDuration:duration animations:^{
            self.view.frame = CGRectMake(0.0f, parentFrame.size.height, parentFrame.size.width, VisilabsNotificationHeight * 3.0f);
        } completion:^(BOOL finished) {
            [self.view removeFromSuperview];
            if (completion) {
                completion();
            }
        }];
    }
}

- (void)didTap:(UITapGestureRecognizer *)gesture
{
    id strongDelegate = self.delegate;
    if (!_isBeingDismissed && gesture.state == UIGestureRecognizerStateEnded && strongDelegate != nil) {
        [strongDelegate notificationController:self wasDismissedWithStatus:YES];
    }
}

- (void)didPan:(UIPanGestureRecognizer *)gesture
{
    if (_canPan) {
        if (gesture.state == UIGestureRecognizerStateBegan && gesture.numberOfTouches == 1) {
            _panStartPoint = [gesture locationInView:self.parentViewController.view];
        } else if (gesture.state == UIGestureRecognizerStateChanged) {
            CGPoint position = [gesture locationInView:self.parentViewController.view];
            CGFloat diffY = position.y - _panStartPoint.y;
            
            if (diffY > 0) {
                position.y = _position.y + diffY * 2.0f;
            } else {
                position.y = _position.y + diffY * 0.1f;
            }
            
            self.view.layer.position = CGPointMake(self.view.layer.position.x, position.y);
        } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
            id strongDelegate = self.delegate;
            if (self.view.layer.position.y > _position.y + VisilabsNotificationHeight / 2.0f && strongDelegate != nil) {
                [strongDelegate notificationController:self wasDismissedWithStatus:NO];
            } else {
                [UIView animateWithDuration:0.2f animations:^{
                    self.view.layer.position = self->_position;
                }];
            }
        }
    }
}

@end

@implementation VisilabsAlphaMaskView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder]) {
        _maskLayer = [VisilabsGradientMaskLayer layer];
        [self.layer setMask:_maskLayer];
        self.opaque = NO;
        _maskLayer.opaque = NO;
        _maskLayer.needsDisplayOnBoundsChange = YES;
        [_maskLayer setNeedsDisplay];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [_maskLayer setFrame:self.bounds];
}

@end

@implementation VisilabsActionButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.layer.backgroundColor = [UIColor colorWithRed:43.0f/255.0f green:43.0f/255.0f blue:52.0f/255.0f alpha:1.0f].CGColor;
        self.layer.cornerRadius = 17.0f;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = 2.0f;
    }
    
    return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted) {
        self.layer.borderColor = [UIColor grayColor].CGColor;
    } else {
        self.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    
    [super setHighlighted:highlighted];
}

@end

@implementation VisilabsBgRadialGradientView

- (void)drawRect:(CGRect)rect
{
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGSize circleSize = CGSizeMake(center.y * 2.0f, center.y * 2.0f);
    CGRect circleFrame = CGRectMake(center.x - center.y, 0.0f, circleSize.width, circleSize.height);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGColorRef colorRef = [UIColor colorWithRed:24.0f / 255.0f green:24.0f / 255.0f blue:31.0f / 255.0f alpha:0.94f].CGColor;
    CGContextSetFillColorWithColor(ctx, colorRef);
    CGContextFillRect(ctx, self.bounds);
    
    CGContextSetBlendMode(ctx, kCGBlendModeCopy);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat comps[] = {96.0f / 255.0f, 96.0f / 255.0f, 124.0f / 255.0f, 0.94f,
        72.0f / 255.0f, 72.0f / 255.0f, 93.0f / 255.0f, 0.94f,
        24.0f / 255.0f, 24.0f / 255.0f, 31.0f / 255.0f, 0.94f,
        24.0f / 255.0f, 24.0f / 255.0f, 31.0f / 255.0f, 0.94f};
    CGFloat locs[] = {0.0f, 0.1f, 0.75, 1.0f};
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, comps, locs, 4);
    
    CGContextAddEllipseInRect(ctx, circleFrame);
    CGContextClip(ctx);
    
    CGContextDrawRadialGradient(ctx, gradient, center, 0.0f, center, circleSize.width / 2.0f, kCGGradientDrawsAfterEndLocation);
    
    
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
    CGContextRestoreGState(ctx);
}

@end

@implementation VisilabsCircleLayer

+ (instancetype)layer {
    VisilabsCircleLayer *cl = (VisilabsCircleLayer *)[super layer];
    cl.circlePadding = 2.5f;
    return cl;
}

- (void)drawInContext:(CGContextRef)ctx
{
    CGFloat edge = 1.5f; //the distance from the edge so we don't get clipped.
    CGContextSetAllowsAntialiasing(ctx, true);
    CGContextSetShouldAntialias(ctx, true);
    
    CGMutablePathRef thePath = CGPathCreateMutable();
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGPathAddArc(thePath, NULL, self.frame.size.width / 2.0f, self.frame.size.height / 2.0f, MIN(self.frame.size.width, self.frame.size.height) / 2.0f - (2 * edge), (float)-M_PI, (float)M_PI, YES);
    
    CGContextBeginPath(ctx);
    CGContextAddPath(ctx, thePath);
    
    CGContextSetLineWidth(ctx, 1.5f);
    CGContextStrokePath(ctx);
    
    CFRelease(thePath);
}

@end

@implementation VisilabsGradientMaskLayer

- (void)drawInContext:(CGContextRef)ctx
{
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGFloat components[] = {
        1.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.9f,
        1.0f, 0.0f};
    
    CGFloat locations[] = {0.0f, 0.7f, 0.8f, 1.0f};
    
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 7);
    CGContextDrawLinearGradient(ctx, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(5.0f, self.bounds.size.height), (CGGradientDrawingOptions)0);
    
    
    NSUInteger bits = (NSUInteger)fabs(self.bounds.size.width) * (NSUInteger)fabs(self.bounds.size.height);
    char *rgba = (char *)malloc(bits);
    srand(124);
    
    for (NSUInteger i = 0; i < bits; ++i) {
        rgba[i] = (rand() % 8);
    }
    
    CGContextRef noise = CGBitmapContextCreate(rgba, (NSUInteger)fabs(self.bounds.size.width), (NSUInteger)fabs(self.bounds.size.height), 8, (NSUInteger)fabs(self.bounds.size.width), NULL, (CGBitmapInfo)kCGImageAlphaOnly);
    CGImageRef image = CGBitmapContextCreateImage(noise);
    
    CGContextSetBlendMode(ctx, kCGBlendModeSourceOut);
    CGContextDrawImage(ctx, self.bounds, image);
    
    CGImageRelease(image);
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    CGContextRelease(noise);
    free(rgba);
}

@end

@implementation VisilabsElasticEaseOutAnimation

- (instancetype)initWithStartValue:(CGRect)start endValue:(CGRect)end andDuration:(double)duration
{
    if ((self = [super init])) {
        self.duration = duration;
        self.values = [self generateValuesFrom:start to:end];
    }
    return self;
}

- (NSArray *)generateValuesFrom:(CGRect)start to:(CGRect)end
{
    NSUInteger steps = (NSUInteger)ceil(60 * self.duration) + 2;
    NSMutableArray *valueArray = [NSMutableArray arrayWithCapacity:steps];
    const double increment = 1.0 / (double)(steps - 1);
    double t = 0.0;
    CGRect range = CGRectMake(end.origin.x - start.origin.x, end.origin.y - start.origin.y, end.size.width - start.size.width, end.size.height - start.size.height);
    
    NSUInteger i;
    for (i = 0; i < steps; i++) {
        float v = (float) -(pow(M_E, -8*t) * cos(12*t)) + 1; // Cosine wave with exponential decay
        
        CGRect value = CGRectMake(start.origin.x + v * range.origin.x,
                                  start.origin.y + v * range.origin.y,
                                  start.size.width + v * range.size.width,
                                  start.size.height + v *range.size.height);
        
        [valueArray addObject:[NSValue valueWithCGRect:value]];
        t += increment;
    }
    
    return [NSArray arrayWithArray:valueArray];
}

@end

