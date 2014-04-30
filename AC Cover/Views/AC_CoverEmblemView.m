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

static const CGFloat _OUTER_SHADOW_SIZE = 90;

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
    
    CGSize frameSize = CGSizeMake(emblem.size.width + 2 * _OUTER_SHADOW_SIZE,
                                  emblem.size.height + 2 * _OUTER_SHADOW_SIZE);
    CGRect f = {0, 0, frameSize};
    self.frame = f;
    self.backgroundColor = [UIColor clearColor];
    
    // Prep the layer to the correct size and center
    CALayer *(^layerWithImage)(CGSize size, UIImage *contents) = ^CALayer *(CGSize size, UIImage *contents) {
        CALayer *l = [CALayer layer];
        l.frame = CGRectMake(0, 0, size.width, size.height);
        l.contentsScale = self.layer.contentsScale;
        l.anchorPoint = CGPointMake(0.5, 0.5);
        l.position = CGPointMake(frameSize.width/2, frameSize.height/2);
        l.contents = (__bridge id)contents.CGImage;
        return l;
    };
    
    // 1. Emblem/mask
    CALayer *emblemLayer = layerWithImage(emblem.size, emblem);
    [self.layer addSublayer:emblemLayer];
    
    
    // 2. Inner shadow image
    _innerShadowLayer = layerWithImage(emblem.size, [UIImage imageNamed:@"emblem-inner-shadow"]);
    // disable layer animation actions
    NSDictionary *newActions = @{@"position": [NSNull null]};
    _innerShadowLayer.actions = newActions;
    _innerShadowLayer.position = CGPointMake(_innerShadowLayer.position.x + _INNER_SHADOW_INIT_OFFSET.x,
                                             _innerShadowLayer.position.y + _INNER_SHADOW_INIT_OFFSET.y);
    
    [self.layer insertSublayer:_innerShadowLayer below:emblemLayer];
    _initShadowPos = _innerShadowLayer.position;
    
    
    // 3. Background circle
    CGFloat inset = 39;
    CGSize circSize = {emblem.size.width-inset, emblem.size.height-inset};
    
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:CGRectMake((frameSize.width-circSize.width)/2, (frameSize.height-circSize.height)/2, circSize.width, circSize.height)];
    CALayer *colorLayer;
    
    UIGraphicsBeginImageContextWithOptions(frameSize, NO, 0.0);
    {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        [[UIColor blackColor] setFill];
        
        [[UIColor ac_yellowColor] setFill];
        CGContextAddPath(ctx, circle.CGPath);
        CGContextSetShadowWithColor(ctx, CGSizeZero, _OUTER_SHADOW_SIZE, [[UIColor blackColor] colorWithAlphaComponent:1.0].CGColor);
        CGContextFillPath(ctx);
        colorLayer = layerWithImage(frameSize, UIGraphicsGetImageFromCurrentImageContext());
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
