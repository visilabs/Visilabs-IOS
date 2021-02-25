//
//  VisilabsViewController.m
//  Visilabs
//
//  Created by visilabs on 12/15/2015.
//  Copyright (c) 2015 visilabs. All rights reserved.
//

#import "VisilabsViewController.h"

#import <CoreLocation/CoreLocation.h>


@interface VisilabsViewController ()

@property (strong, nonatomic)  UITextField *exVisitorIDText;
@property (strong, nonatomic)  UITextField *productCodeText;
@property (strong, nonatomic)  UITextField *zoneIDText;
@property (strong, nonatomic)  UITextField *pageNameText;
@property (weak, nonatomic)  UILabel *favoriteAttributesLabel;

@property (weak, nonatomic) IBOutlet UILabel *favoriteAttributeResultsLabel;
@property (weak, nonatomic) IBOutlet UILabel *recommendationResultsLabel;


@end

@implementation VisilabsViewController


@synthesize exVisitorIDText;
@synthesize productCodeText;
@synthesize zoneIDText;
@synthesize pageNameText;


- (IBAction)sendCampaignParameters:(id)sender {
    
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    [properties setObject:@"123456" forKey:@"OM.pbid"];
    [properties setObject:@"" forKey:@"OM.ppr"];
    [properties setObject:@"" forKey:@"OM.pu"];
    [properties setObject:@"" forKey:@"OM.pb"];
    [[Visilabs callAPI] customEvent:@"basket" withProperties:properties];
    
    /*
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    [properties setObject:@"euromsg campaign" forKey:@"utm_campaign"];
    [properties setObject:@"euromsg" forKey:@"utm_source"];
    [properties setObject:@"push" forKey:@"utm_medium"];
    [[Visilabs callAPI] sendCampaignParameters:properties];
     */
}

- (IBAction)testFavoriteAttribute:(id)sender {
    VisilabsTargetRequest * targetRequest = [[Visilabs callAPI] buildActionRequest:VisilabsTargetRequestTypeFavorite withActionID:@"188"];
    void (^ successBlock)(VisilabsResponse *) = ^(VisilabsResponse * response) {
        NSArray *favoriteAttributeActions = [response favoriteAttributeActions];
        if(favoriteAttributeActions){
            for (NSObject * object in favoriteAttributeActions) {
                if([object isKindOfClass:[NSDictionary class]]){
                    NSDictionary *favoriteAttributeAction = (NSDictionary*)object;
                    NSDictionary *actionData = [favoriteAttributeAction objectForKey:@"actiondata"];
                    NSDictionary *favorites = [actionData objectForKey:@"favorites"];
                    if(favorites)
                    {
                        NSArray *categories = [favorites objectForKey:@"category"];
                        NSArray *brands = [favorites objectForKey:@"brand"];
                        NSArray *titles = [favorites objectForKey:@"title"];
                        
                        int counter = 1;
                        if(categories)
                        {
                            for (NSString * category in categories)
                            {
                                NSLog(@"Favorite Category %i: %@", counter, category);
                                counter++;
                            }
                        }

                        counter = 1;
                        
                        if(brands)
                        {
                            for (NSString * brand in brands)
                            {
                                NSLog(@"Favorite Brand %i: %@", counter, brand);
                                counter++;
                            }
                        }
                        
                        counter = 1;
                        
                        if(titles)
                        {
                            for (NSString * title in titles)
                            {
                                NSLog(@"Favorite Title %i: %@", counter, title);
                                counter++;
                            }
                        }
                        
                    }
                    
                }
            }
        }
    };
    
    void (^ failBlock)(VisilabsResponse *) =^(VisilabsResponse * response){
        NSLog(@"Failed to call. Response = %@", [response.error description]);
    };
    
    [targetRequest execAsyncWithSuccess:successBlock AndFailure:failBlock];
}

- (IBAction)testRecommendation:(id)sender {
    NSMutableArray *filters = [[NSMutableArray alloc] init];
    /*for (int i = 0; i<5; i++) {
        VisilabsTargetFilter *filter = [[VisilabsTargetFilter alloc] init];
        filter.attribute = [NSString stringWithFormat:@"A filter: %d", i];
        filter.value = [NSString stringWithFormat:@"A valç: %d", i];
        filter.filterType = [NSString stringWithFormat:@"A tıpğ: %d", i];
        [filters addObject:filter];
    }*/
    
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    /*[dic setObject:@"what" forKey:@"OM.w.f"];
    [dic setObject:@"the" forKey:@"OM.exVisitorID"];
    [dic setObject:@"f" forKey:@"OM.lpvs"];
    [dic setObject:@"the" forKey:@"OM.guru"];*/
    
    VisilabsTargetRequest *request = [[Visilabs callAPI] buildTargetRequest:@"6" withProductCode:@"pc" withProperties:dic withFilters:filters];
    
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
                    
                    NSLog(@"ProductAttributes:%@-%@-%@-%@-%@-%f-%f-%@-%@-%i-%i-%f-%@-%@-%@-%@-%@-%@-%@", title,img,code,destURL,brand,price,discountedPrice,currency,discountCurrency,rating,comment,discount
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    exVisitorIDText.text = @"egemengulkilik@gmail.com";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)login:(id)sender {
    [[Visilabs callAPI] login:exVisitorIDText.text];
    [self.view endEditing:YES];
}


- (void)signUp:(id)sender {
    [[Visilabs callAPI] signUp:exVisitorIDText.text];
    [self.view endEditing:YES];
}

- (void)customEvent:(id)sender {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:productCodeText.text forKey:@"OM.pv"];
    [dic setObject:@"isveren" forKey:@"OM.kullanici_tipi"];
    
    
    [[Visilabs callAPI] customEvent:pageNameText.text withProperties:dic];
    [self.view endEditing:YES];
}

- (void)suggest:(id)sender {
    
    
}



- (void)showMini:(id)sender {
    //[[Visilabs callAPI] showNotification:@"dene"];
    
    [[Visilabs callAPI] customEvent:@"mini" withProperties:nil];
    //[[Visilabs callAPI] showNotification:@"dene"];
}


- (void)showFull:(id)sender {
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:@"zahir" forKey:@"OM.pv"];
    [dic setObject:@"asdf" forKey:@"OM.exVisitorID"];
    [[Visilabs callAPI] customEvent:@"full" withProperties:dic];
}


- (void)show3:(id)sender {
    [[Visilabs callAPI] showNotification:@"dene"];
}

- (void)show:(id)sender {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:@"zahir" forKey:@"OM.pv"];
    [[Visilabs callAPI] customEvent:@"Kampanya_Detay_Ekrani_Erdost basit kampanya postu" withProperties:dic];
    //[[Visilabs callAPI] showNotification:@"dene"];
}

-(void)bringGeofences{
    //NSString *geofenceID =  (NSString*)[theTimer userInfo];
    NSArray *geofences = [[VisilabsGeofenceStatus sharedInstance] arrayGeofenceFetchList];
    if(geofences){
        for (VisilabsServerGeofence *geofence in geofences){
            /*if([geofence.suid isEqualToString:geofenceID]){
                
                if(geofence.isInside){
                    NSArray *elements = [geofenceID componentsSeparatedByString:@"_"];
                    if(elements && elements.count == 3){
                        //[[VisilabsGeofenceLocationManager sharedInstance] sendPushNotification:elements[1]];
                    }
                }
                return;
            }*/
        }
    }
    
}





@end
