//
//  VisilabsGeofenceInterceptor.m
//  Pods
//
//  Created by Visilabs on 15.08.2016.
//
//

#import "VisilabsGeofenceInterceptor.h"

@implementation VisilabsGeofenceInterceptor

#pragma mark - life cycle

-(id)init
{
    if (self = [super init])
    {
        self.firstResponder = nil;
        self.secondResponder = nil;
    }
    return self;
}

#pragma mark - pass handling

- (void)setFirstResponder:(id)firstResponder_
{
    //Fix a dead loop, if firstResponder_ is self, the following forwardingTargetForSelector and respondsToSelector dead loop.
    if (firstResponder_ != self)
    {
        _firstResponder = firstResponder_;
    }
}

-(void)setSecondResponder:(id)secondResponder_
{
    //Fix a dead loop, if secondResponder_ is self, the following forwardingTargetForSelector and respondsToSelector dead loop.
    //Also need to check not first Responder, because some first Responder also call backup Responder for supplement functions, if they are same cause dead loop.
    if (secondResponder_ != self && secondResponder_ != self.firstResponder)
    {
        _secondResponder = secondResponder_;
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self.firstResponder respondsToSelector:aSelector])
    {
        return YES;
    }
    else if ([self.secondResponder respondsToSelector:aSelector])
    {
        return YES;
    }
    else
    {
        return [super respondsToSelector:aSelector];
    }
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.firstResponder respondsToSelector:aSelector])
    {
        return self.firstResponder;
    }
    else if ([self.secondResponder respondsToSelector:aSelector])
    {
        return self.secondResponder;
    }
    else
    {
        return [super forwardingTargetForSelector:aSelector];
    }
}

@end