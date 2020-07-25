# Visilabs

[![Version](https://img.shields.io/cocoapods/v/Visilabs.svg?style=flat)](http://cocoapods.org/pods/Visilabs)
[![License](https://img.shields.io/cocoapods/l/Visilabs.svg?style=flat)](http://cocoapods.org/pods/Visilabs)
[![Platform](https://img.shields.io/cocoapods/p/Visilabs.svg?style=flat)](http://cocoapods.org/pods/Visilabs)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Visilabs is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Visilabs"
```

## Favorite Attributes

```objc
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
```


## Author

visilabs, contact@visilabs.com

## License

Visilabs is available under the MIT license. See the LICENSE file for more info.
