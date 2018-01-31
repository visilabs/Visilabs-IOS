//
//  NotificationViewController.m
//  ContentExtension
//
//  Created by İnan Kubilay on 14/11/2017.
//  Copyright © 2017 visilabs. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>

@interface NotificationViewController () <UNNotificationContentExtension>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;


@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any required interface initialization here.
}

- (void)didReceiveNotification:(UNNotification *)notification {
    //self.label.text = notification.request.content.body;
    NSDictionary *dict = notification.request.content.userInfo;
    
    for (UNNotificationAttachment *attachment in notification.request.content.attachments)
    {
        if ([dict objectForKey:@"pic_url"] && [attachment.identifier
                                               isEqualToString:[[dict objectForKey:@"pic_url"] lastPathComponent]])
        {
            if ([attachment.URL startAccessingSecurityScopedResource])
            {
                NSData *imageData = [NSData dataWithContentsOfURL:attachment.URL];
                
                self.imageView.image = [UIImage imageWithData:imageData];
                
                // This is done if the spread url is not downloaded then both the image view will show cover url.
                self.imageView.image = [UIImage imageWithData:imageData];
                [attachment.URL stopAccessingSecurityScopedResource];
                
                
            }
        }
    }
    
}

@end
