#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "VisilabsNotification.h"
#import "VisilabsDefines.h"

@interface VisilabsNotification ()

- (instancetype)initWithID:(NSUInteger)ID type:(NSString *)type title:(NSString *)title body:(NSString *)body buttonText:(NSString *)buttonText buttonURL:(NSURL *)buttonURL imageURL:(NSURL *)imageURL visitorData:(NSString *)visitorData visitData:(NSString *)visitData queryString:(NSString *)queryString;

@end


@implementation VisilabsNotification

NSString *const VisilabsNotificationTypeMini = @"mini";
NSString *const VisilabsNotificationTypeFull = @"full";

+ (VisilabsNotification *)notificationWithJSONObject:(NSDictionary *)object
{
    if (object == nil) {
        DLog(@"notif json object should not be nil");
        return nil;
    }
    
    NSNumber *ID = object[@"actid"];
    if (!([ID isKindOfClass:[NSNumber class]] && [ID integerValue] > 0)) {
        DLog(@"invalid notification id: %@", ID);
        return nil;
    }
    
    
    NSDictionary *actionData = object[@"actiondata"];
    
    if (!actionData) {
        return nil;
    }
    
    
    NSString *type = actionData[@"msg_type"];
    if (![type isKindOfClass:[NSString class]]) {
        DLog(@"invalid notification type: %@", type);
        return nil;
    }
    
    NSString *title = actionData[@"msg_title"];
    if (![title isKindOfClass:[NSString class]]) {
        DLog(@"invalid notification title: %@", title);
        return nil;
    }
    
    NSString *body = actionData[@"msg_body"];
    if (![body isKindOfClass:[NSString class]]) {
        DLog(@"invalid notification body: %@", body);
        return nil;
    }
    
    NSString *buttonText = actionData[@"btn_text"];
    if (![buttonText isKindOfClass:[NSString class]]) {
        DLog(@"invalid notification cta: %@", buttonText);
        return nil;
    }
    
    NSURL *buttonURL = nil;
    NSObject *URLString = actionData[@"ios_lnk"];
    if (URLString != nil && ![URLString isKindOfClass:[NSNull class]]) {
        //if (![URLString isKindOfClass:[NSString class]] || [(NSString *)URLString length] == 0) {
        if (![URLString isKindOfClass:[NSString class]]) {
            DLog(@"invalid notification URL: %@", URLString);
            return nil;
        }
        
        buttonURL = [NSURL URLWithString:(NSString *)URLString];
        if (buttonURL == nil) {
            DLog(@"invalid notification URL: %@", URLString);
            return nil;
        }
    }
    
    NSURL *imageURL = nil;
    NSString *imageURLString = actionData[@"img"];
    if (imageURLString != nil && ![imageURLString isKindOfClass:[NSNull class]]) {
        if (![imageURLString isKindOfClass:[NSString class]]) {
            DLog(@"invalid notification image URL: %@", imageURLString);
            return nil;
        }
        
        NSString *escapedUrl = [imageURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        imageURL = [NSURL URLWithString:escapedUrl];
        if (imageURL == nil) {
            DLog(@"invalid notification image URL: %@", imageURLString);
            return nil;
        }
        
        NSString *imagePath = imageURL.path;
        /*if ([type isEqualToString:VisilabsNotificationTypeFull]) {
            NSString *imageName = [imagePath stringByDeletingPathExtension];
            NSString *extension = [imagePath pathExtension];
            imagePath = [[imageName stringByAppendingString:@"@2x"] stringByAppendingPathExtension:extension];
        }*/
        
        if ([type isEqualToString:VisilabsNotificationTypeMini]) {
            NSString *imageName = [imagePath stringByDeletingPathExtension];
            NSString *extension = [imagePath pathExtension];
            imagePath = [[imageName stringByAppendingString:@"@2x"] stringByAppendingPathExtension:extension];
        }
        
        
        imagePath = [imagePath stringByAddingPercentEscapesUsingEncoding:NSStringEncodingConversionExternalRepresentation];
        imageURL = [[NSURL alloc] initWithScheme:imageURL.scheme host:imageURL.host path:imagePath];
        
        if (imageURL == nil) {
            DLog(@"invalid notification image URL: %@", imageURLString);
            return nil;
        }
    }
    
    
    NSString *visitorData = actionData[@"visitor_data"];
    if (![visitorData isKindOfClass:[NSString class]]) {
        DLog(@"invalid notification visitorData: %@", visitorData);
        return nil;
    }
    
    NSString *visitData = actionData[@"visit_data"];
    if (![visitData isKindOfClass:[NSString class]]) {
        DLog(@"invalid notification visitData: %@", visitData);
        return nil;
    }
    
    NSString *queryString = actionData[@"qs"];
    if (![queryString isKindOfClass:[NSString class]]) {
        DLog(@"invalid notification queryString: %@", queryString);
        return nil;
    }
    
    return [[VisilabsNotification alloc] initWithID:[ID unsignedIntegerValue] type:type title:title body:body buttonText:buttonText buttonURL:buttonURL imageURL:imageURL visitorData:visitorData visitData:visitData queryString:queryString];
}

- (instancetype)initWithID:(NSUInteger)ID type:(NSString *)type title:(NSString *)title body:(NSString *)body buttonText:(NSString *)buttonText buttonURL:(NSURL *)buttonURL imageURL:(NSURL *)imageURL visitorData:(NSString *)visitorData visitData:(NSString *)visitData queryString:(NSString *)queryString
{
    if (self = [super init]) {
        BOOL valid = YES;
        
        if (!title) {
            valid = NO;
            DLog(@"Notification title nil or empty: %@", title);
        }
        
        if (!body) {
            valid = NO;
            DLog(@"Notification body nil or empty: %@", body);
        }
        
        if (!([type isEqualToString:VisilabsNotificationTypeFull] || [type isEqualToString:VisilabsNotificationTypeMini])) {
            valid = NO;
            DLog(@"Invalid notification type: %@, must be %@ or %@", type, VisilabsNotificationTypeMini, VisilabsNotificationTypeFull);
        }
        
        if([type isEqualToString:VisilabsNotificationTypeMini] &&(!body || body.length < 1)){
            body = [NSString stringWithString:title];
        }
        
        if (valid) {
            _ID = ID;
            self.type = type;
            self.title = title;
            self.body = body;
            self.imageURL = imageURL;
            self.buttonText = buttonText;
            self.buttonURL = buttonURL;
            self.image = nil;
            self.visitorData = visitorData;
            self.visitData = visitData;
            self.queryString = queryString;
        } else {
            self = nil;
        }
    }
    
    return self;
}

- (NSData *)image
{
    if (_image == nil && _imageURL != nil) {
        NSError *error = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:_imageURL options:NSDataReadingMappedIfSafe error:&error];
        if (error || !imageData) {
            DLog(@"image failed to load from URL: %@", _imageURL);
            return nil;
        }
        _image = imageData;
    }
    return _image;
}

@end
