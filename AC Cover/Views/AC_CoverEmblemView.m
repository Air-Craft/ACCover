//
//  AC_CoverEmblemView.m
//  AC Cover
//
//  Created by Hari Karam Singh on 17/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "AC_CoverEmblemView.h"
#import "UIColor+AC_Branding.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static const CGFloat _MAX_SHADOW_SIZE = 80;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation AC_CoverEmblemView
{
    UIImage *_emblemImg;
    CMMotionManager *_motionManager;
    CMQuaternion _initRotation;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)coverEmblemViewWithMotionManager:(CMMotionManager *)motionManger
{
    // Load the emblem image first to determine the size the view needs to be
    // Shadow can go L/R/B but not above
    UIImage *emblem = [UIImage imageNamed:@"cover_emblem"];
    NSParameterAssert(emblem);
    CGSize frameSize = CGSizeMake(emblem.size.width + 2 * _MAX_SHADOW_SIZE,
                                  emblem.size.height + 2 * _MAX_SHADOW_SIZE);
    CGRect f = {0, 0, frameSize};
    AC_CoverEmblemView *me = [[AC_CoverEmblemView alloc] initWithFrame:f];
    if (me) {
        me->_emblemImg = emblem;
        me->_motionManager = motionManger;
        me->_initRotation = motionManger.deviceMotion.attitude.quaternion;
        me.backgroundColor = [UIColor clearColor];
        me.layer.shadowColor = [UIColor blackColor].CGColor;
        me.layer.shadowOffset = CGSizeMake(0, 4);
        me.layer.shadowRadius = 4;
        me.layer.shadowOpacity = 0.8;
        return me;
    }
    return nil;
    
}

/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    UIColor *outerShadowColor = [UIColor.blackColor colorWithAlphaComponent:0.9];
    UIColor *innerShadowColor = [UIColor.blackColor colorWithAlphaComponent:0.6];
    
    // Calc the shadow attribs based on the delta rotation
    CMQuaternion newRotation = _motionManager.deviceMotion.attitude.quaternion;
    
    CGSize outerShadowOffset = {
        (newRotation.y - _initRotation.y) * _MAX_SHADOW_SIZE,
        (newRotation.x - _initRotation.x) * _MAX_SHADOW_SIZE,
    };
    CGSize innerShadowOffset = {
        (newRotation.y - _initRotation.y) * 10,
        (newRotation.x - _initRotation.x) * 10,
    };
    
    
    CGRect circBounds = {
        _MAX_SHADOW_SIZE + 5,
        _MAX_SHADOW_SIZE + 5,
        _emblemImg.size.width - 10,
        _emblemImg.size.width - 10
    };
    UIBezierPath *pth = [UIBezierPath bezierPathWithOvalInRect:circBounds];
    [[UIColor ac_yellowColor] setFill];
    CGContextSetShadowWithColor(ctx, outerShadowOffset, _MAX_SHADOW_SIZE, outerShadowColor.CGColor);
    [pth fill];
    
    
    // Now shadow the cutout graphic to create an inner shadow
    CGContextSetShadowWithColor(ctx,
                                innerShadowOffset,
                                3,
                                innerShadowColor.CGColor);
    [_emblemImg drawAtPoint:CGPointMake(_MAX_SHADOW_SIZE, _MAX_SHADOW_SIZE)];
    
    
}



@end
