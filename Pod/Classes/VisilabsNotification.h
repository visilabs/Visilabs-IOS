#import <Foundation/Foundation.h>

@interface VisilabsNotification : NSObject

extern NSString *const VisilabsNotificationTypeMini;
extern NSString *const VisilabsNotificationTypeFull;

@property (nonatomic, readonly) NSUInteger ID;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *body;
@property (nonatomic, strong) NSURL *imageURL;


@property (nonatomic, strong) NSString *buttonText;
@property (nonatomic, strong) NSURL *buttonURL;

@property (nonatomic, strong) NSString *visitorData;
@property (nonatomic, strong) NSString *visitData;
@property (nonatomic, strong) NSString *queryString;

@property (nonatomic, strong) NSData *image;

+ (VisilabsNotification *)notificationWithJSONObject:(NSDictionary *)object;

- (instancetype)init __unavailable;

@end
