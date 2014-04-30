//
//  AC_CoverEmblemView.m
//  AC Cover
//
//  Created by Hari Karam Singh on 17/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "AC_CoverEmblemView.h"
#import "UIColor+AC_Branding.h"
#import "MarshmallowMath.h"


/////////////////////////////////////////////////////////////////////////
#pragma mark - Consts
/////////////////////////////////////////////////////////////////////////

static const CGPoint _INNER_SHADOW_INIT_OFFSET = { 0, 3 };
static const CGPoint _INNER_SHADOW_OFFSET_MIN = { -2, -5 };
static const CGPoint _INNER_SHADOW_OFFSET_MAX = { +2, 1};

static const CGFloat _MAX_SHADOW_SIZE = 75;

/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation AC_CoverEmblemView
{
    CALayer *_innerShadowLayer;
    CGPoint _initShadowPos;
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
/////////////////////////////////////////////////////////////////////////

+ (instancetype)coverEmblemView
{
    // Load the emblem image first to determine the size the view needs to be
    // Shadow can go L/R/B but not above
    AC_CoverEmblemView *me = [[AC_CoverEmblemView alloc] init];
    if (me) {
        [me _setupLayers];
        return me;
    }
    return nil;
}

//---------------------------------------------------------------------

/** Construct the view layers: 1. Mask, 2. Shadow, 3. Color circle.  Also sets the view frame from the image size */
- (void)_setupLayers
{
    // 0. View bounds
    UIImage *emblem = [UIImage imageNamed:@"emblem-masked"];
    NSParameterAssert(emblem);
    CGSize frameSize = CGSizeMake(emblem.size.width,
                                  emblem.size.height);
    CGRect f = {0, 0, frameSize};
    self.frame = f;
    self.backgroundColor = [UIColor clearColor];
    
    
    // 1. Emblem/mask
    CALayer *emblemLayer = [CALayer layer];
    emblemLayer.frame = self.frame;
    emblemLayer.contents = (__bridge id)(emblem.CGImage);
    [self.layer addSublayer:emblemLayer];
    
    
    // 2. Inner shadow image
    _innerShadowLayer = [CALayer layer];
    _innerShadowLayer.contentsScale = self.layer.contentsScale;
    // disable layer actions
    NSDictionary *newActions = @{@"position": [NSNull null]};
    _innerShadowLayer.actions = newActions;
    
    _innerShadowLayer.contents = (__bridge id)[UIImage imageNamed:@"emblem-inner-shadow"].CGImage;
    [self.layer insertSublayer:_innerShadowLayer below:emblemLayer];
    _innerShadowLayer.frame = CGRectMake(_INNER_SHADOW_INIT_OFFSET.x,
                                         _INNER_SHADOW_INIT_OFFSET.y,
                                         self.frame.size.width,
                                         self.frame.size.height);
    _initShadowPos = _innerShadowLayer.position;
    
    
    // 3. Background circle
    CGFloat inset = 39;
    CGRect circBounds = {0, 0, self.frame.size.width-inset, self.frame.size.height-inset};
    CALayer *colorLayer = [CALayer layer];
    colorLayer.contentsScale = self.layer.contentsScale;
    colorLayer.bounds = circBounds;
    colorLayer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    colorLayer.anchorPoint = CGPointMake(0.5, 0.5);
    
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:circBounds];
    UIGraphicsBeginImageContext(circBounds.size);
    {
        [[UIColor ac_yellowColor] setFill];
        [circle fill];
        colorLayer.contents = (__bridge id)UIGraphicsGetImageFromCurrentImageContext().CGImage;
    }
    UIGraphicsEndImageContext();
    [self.layer insertSublayer:colorLayer below:_innerShadowLayer];
}

/////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
/////////////////////////////////////////////////////////////////////////

- (void)setRelativeAngleOffset:(CGPoint)relativeAngleOffset
{
    // Rotation around X offsets Y position of the shadow and vice versa
    // Take note of the signs too...
    CGPoint newPos = _initShadowPos;
    newPos.x += MM_MapBilinearRange(relativeAngleOffset.y, -1, 0, 1, _INNER_SHADOW_OFFSET_MIN.x, 0, _INNER_SHADOW_OFFSET_MAX.x);
    newPos.y += MM_MapBilinearRange(relativeAngleOffset.x, -1, 0, 1, _INNER_SHADOW_OFFSET_MIN.y, 0, _INNER_SHADOW_OFFSET_MAX.y);
    _innerShadowLayer.position = newPos;

}


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

//- (void)drawRect:(CGRect)rect
//{
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//
//    UIColor *outerShadowColor = [UIColor.blackColor colorWithAlphaComponent:1.0];
//    UIColor *innerShadowColor = [UIColor.blackColor colorWithAlphaComponent:0.6];
//    
//    // Calc the shadow attribs based on the delta rotation
//    CMQuaternion newRotation = _motionManager.deviceMotion.attitude.quaternion;
//    
//    CGSize outerShadowOffset = {
//        0,//(newRotation.y - _initRotation.y) * _MAX_SHADOW_SIZE,
//        0,//_MAX_SHADOW_SIZE/2,//(newRotation.x - _initRotation.x) * _MAX_SHADOW_SIZE,
//    };
//    CGSize innerShadowOffset = {
//        (newRotation.y - _initRotation.y) * 10,
//        (newRotation.x - _initRotation.x) * 10,
//    };
//    
//    CGRect circBounds = {
//        _MAX_SHADOW_SIZE + 5,
//        _MAX_SHADOW_SIZE + 5,
//        _emblemImg.size.width - 10,
//        _emblemImg.size.width - 10
//    };
//    UIBezierPath *pth = [UIBezierPath bezierPathWithOvalInRect:circBounds];
//    [[UIColor ac_yellowColor] setFill];
//    CGContextSetShadowWithColor(ctx, outerShadowOffset, _MAX_SHADOW_SIZE*1.0, outerShadowColor.CGColor);
//    [pth fill];
//    
//    
//    // Now shadow the cutout graphic to create an inner shadow
//    CGContextSetShadowWithColor(ctx,
//                                innerShadowOffset,
//                                3,
//                                innerShadowColor.CGColor);
//    [_emblemImg drawAtPoint:CGPointMake(_MAX_SHADOW_SIZE, _MAX_SHADOW_SIZE)];
//    
//    
//}



@end
