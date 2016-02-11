//
//  VisilabsViewController.m
//  Visilabs
//
//  Created by visilabs on 12/15/2015.
//  Copyright (c) 2015 visilabs. All rights reserved.
//

#import "VisilabsViewController.h"

@interface VisilabsViewController ()

@property (strong, nonatomic) IBOutlet UITextField *exVisitorIDText;

@property (strong, nonatomic) IBOutlet UITextField *productCodeText;


@property (strong, nonatomic) IBOutlet UITextField *zoneIDText;

@property (strong, nonatomic) IBOutlet UITextField *pageNameText;





@end

@implementation VisilabsViewController


@synthesize exVisitorIDText;
@synthesize productCodeText;
@synthesize zoneIDText;
@synthesize pageNameText;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)login:(id)sender {
    [[Visilabs callAPI] login:exVisitorIDText.text];
}


- (IBAction)signUp:(id)sender {
    [[Visilabs callAPI] signUp:exVisitorIDText.text];
}

- (IBAction)customEvent:(id)sender {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:productCodeText.text forKey:@"OM.pv"];
    
    [[Visilabs callAPI] customEvent:pageNameText.text withProperties:dic];
}

- (IBAction)suggest:(id)sender {
    VisilabsTargetRequest *request = [[Visilabs callAPI] buildTargetRequest:@"9" withProductCode:productCodeText.text];
    
    void (^ successBlock)(VisilabsResponse *) = ^(VisilabsResponse * response) {
        NSLog(@"Response: %@", response.rawResponseAsString);
        NSArray *parsedArray = [response responseArray];
        if(parsedArray){
            for (NSObject * object in parsedArray) {
                if([object isKindOfClass:[NSDictionary class]]){
                    NSDictionary *product = (NSDictionary*)object;
                    NSString *title = [product objectForKey:@"title"];
                    NSString *img = [product objectForKey:@"img"];
                    NSString *code = [product objectForKey:@"code"];
                    NSString *destURL = [product objectForKey:@"dest_url"];
                    NSString *brand = [product objectForKey:@"brand"];
                    double price = [[product objectForKey:@"price"] doubleValue];
                    double discountedPrice = [[product objectForKey:@"dprice"] doubleValue];
                    NSString *currency = [product objectForKey:@"cur"];
                    NSString *discountCurrency = [product objectForKey:@"dcur"];
                    int rating = [[product objectForKey:@"rating"] intValue];
                    int comment = [[product objectForKey:@"comment"] intValue];
                    double discount = [[product objectForKey:@"discount"] doubleValue];
                    BOOL freeShipping = [[product objectForKey:@"freeshipping"] boolValue];
                    BOOL sameDayShipping = [[product objectForKey:@"samedayshipping"] boolValue];
                    NSString *attr1 = [product objectForKey:@"attr1"];
                    NSString *attr2 = [product objectForKey:@"attr2"];
                    NSString *attr3 = [product objectForKey:@"attr3"];
                    NSString *attr4 = [product objectForKey:@"attr4"];
                    NSString *attr5 = [product objectForKey:@"attr5"];
                    
                    NSLog(@"%@-%@-%@-%@-%@-%f-%f-%@-%@-%i-%i-%f-%@-%@-%@-%@-%@-%@-%@", title,img,code,destURL,brand,price,discountedPrice,currency,discountCurrency,rating,comment,discount
                          ,freeShipping ? @"YES" : @"NO"
                          ,sameDayShipping? @"YES" : @"NO"
                          , attr1, attr2, attr3, attr4, attr5);
                    NSLog(@"Product: %@", product);
                }
            }
        }
    };
    
    void (^ failBlock)(VisilabsResponse *) =^(VisilabsResponse * response){
        NSLog(@"Failed to call. Response = %@", [response.error description]);
    };
    
    
    [request execAsyncWithSuccess:successBlock AndFailure:failBlock];
}



- (IBAction)showMini:(id)sender {
    [[Visilabs callAPI] showNotification:@"dene"];
}


- (IBAction)showFull:(id)sender {
    [[Visilabs callAPI] showNotification:@"dene"];
}


- (IBAction)show3:(id)sender {
    [[Visilabs callAPI] showNotification:@"dene"];
}

- (IBAction)show:(id)sender {
    [[Visilabs callAPI] showNotification:@"dene"];
}









@end
