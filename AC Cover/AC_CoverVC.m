//
//  ACViewController.m
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

@import CoreMotion;

#import "AC_CoverVC.h"
#import "AC_CoverView.h"
#import "AC_CoverEmblemView.h"


/////////////////////////////////////////////////////////////////////////
#pragma mark - Constants
/////////////////////////////////////////////////////////////////////////

static float _MAX_TILT_ANGLE = 0.25 * M_PI_4;
static float _INIT_PITCH_TILT_ANGLE = 10 * M_PI/180;

typedef struct {
    float pitch;
    float roll;
} ACTiltOrientation;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Debug/Calibation
/////////////////////////////////////////////////////////////////////////



static float attnConst=0.0, attnLin=15.97, attnQuad=9.81;
static float light0X=0.19,/*2.72,*/ light0Y=0.45,/*3.98,*/ light0Z=-1.20/*-0.30*/;
static float diffInts=2.78, specInts=13.05, edgeFaceSplit=6.5;
static float shine=20.00;


/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@interface AC_CoverVC()
{
    __weak IBOutlet UISegmentedControl *_paramSelector;
    __weak IBOutlet UITextView *_console;
}
- (IBAction)_togglePanels;

@end

/////////////////////////////////////////////////////////////////////////
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@implementation AC_CoverVC
{
    AC_CoverEmblemView *_emblemView;
    CMMotionManager *_motionManager;
    
    CADisplayLink *_updater;
    
    NSMutableArray *_activeTouches;
    
    ACTiltOrientation _initTilt;
    
    UIPanGestureRecognizer *_emblemPan;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _activeTouches = NSMutableArray.array;
    
    _motionManager = [[CMMotionManager alloc] init];
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
//    ACTiltOrientation t = { _INIT_PITCH_TILT_ANGLE, 0 };
    CMAttitude *att = _motionManager.deviceMotion.attitude;
    ACTiltOrientation tilt = {att.pitch, att.roll};
    _initTilt = tilt;
    
    [(AC_CoverView *)self.view setupWithMotionManager:_motionManager];

    _emblemView = [AC_CoverEmblemView coverEmblemView];
//    [_emblemView setMultipleTouchEnabled:YES];
    _emblemPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handleEmblemPan:)];
    [_emblemView addGestureRecognizer:_emblemPan];
    

    [_emblemView setCenter:self.view.center];
    [self.view addSubview:_emblemView];
    [_emblemView setNeedsDisplay];
    
    
    _updater = [CADisplayLink displayLinkWithTarget:self selector:@selector(_updateWithSender:)];
    [_updater addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

    [self.view setMultipleTouchEnabled:YES];
    
#ifdef AC_CALIBRATE
    [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(_setDefs) userInfo:nil repeats:NO];
#endif
}

#ifdef AC_CALIBRATE
- (void)_setDefs
{
    AC_CoverView *coverView = (AC_CoverView *)self.view;
    [coverView setUniform:@"u_attnConst" withFloat:attnConst];
    [coverView setUniform:@"u_attnLinear" withFloat:attnLin];
    [coverView setUniform:@"u_attnQuad" withFloat:attnQuad];
    
    GLKVector4 pos = GLKVector4Make(light0X, light0Y, light0Z, 0);
    [coverView setUniform:@"u_light0Pos" withVec4:pos];
    
    [coverView setUniform:@"u_edgeFaceSplitFactor" withFloat:edgeFaceSplit];
    [coverView setUniform:@"u_diffuseIntensity" withFloat:diffInts];
    [coverView setUniform:@"u_specularIntensity" withFloat:specInts];
    [coverView setUniform:@"u_shininess" withFloat:shine];
    [self _updateConsole];
}
#endif

- (IBAction)_togglePanels
{
    _paramSelector.hidden = !_paramSelector.hidden;
    _console.hidden = !_console.hidden;
}

- (void)_handleEmblemPan:(UIPanGestureRecognizer *)gr
{
    CGPoint delta = [gr translationInView:self.view];
    _emblemView.center = CGPointMake(self.view.frame.size.width/2 + delta.x, self.view.frame.size.height/2 + delta.y);
    AC_CoverView *coverView = (AC_CoverView *)self.view;
    coverView.globalPositionOffset = delta;
    CGFloat retraction = (delta.x * delta.x + delta.y * delta.y) / (2 * (self.view.frame.size.width/4 * self.view.frame.size.width/4));
    retraction = MAX(0.0, MIN(1.0, retraction));
    coverView.retraction = retraction;
    NSLog(@"%.2f %.2f, %.2f", delta.x, delta.y, retraction);
}


- (void)_updateWithSender:(id)sender
{
    // Get the tilt offset and normalise/cap it to our MIN/MAX
    CMAttitude *att = _motionManager.deviceMotion.attitude;
    ACTiltOrientation newTilt = { att.pitch, att.roll};
    
    CGPoint rotOffsetNormed = {
        (newTilt.pitch - _initTilt.pitch) / (_MAX_TILT_ANGLE),
        (newTilt.roll - _initTilt.roll) / (_MAX_TILT_ANGLE),
    };
    rotOffsetNormed.x = MIN(1.0, MAX(-1.0, rotOffsetNormed.x));
    rotOffsetNormed.y = MIN(1.0, MAX(-1.0, rotOffsetNormed.y));
    
    _emblemView.relativeAngleOffset = rotOffsetNormed;
    
    AC_CoverView *coverView = (AC_CoverView *)self.view;
    coverView.relativeAngleOffset = rotOffsetNormed;
    
//    [_emblemView setNeedsDisplay];
}


#ifdef AC_CALIBRATE

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *t in touches) {
        NSUInteger idx = _activeTouches.count;
        [_activeTouches addObject:t];
        [self _updateForTouch:t withIndex:idx];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *t in touches) {
        NSUInteger idx = [_activeTouches indexOfObject:t];
        [self _updateForTouch:t withIndex:idx];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_activeTouches removeObjectsInArray:touches.allObjects];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_activeTouches removeObjectsInArray:touches.allObjects];
}


- (void)_updateForTouch:(UITouch *)touch withIndex:(NSUInteger)touchIdx
{
    CGPoint pt = [touch locationInView:self.view];
    CGFloat nX = pt.x / self.view.bounds.size.width;
    CGFloat nY = 1 - (pt.y / (self.view.bounds.size.height - 40.)); // make 0 at bottom
    nY = MAX(nY, 0);
    
    AC_CoverView *coverView = (AC_CoverView *)self.view;
    
    // tracking vars for output etc.
    switch (_paramSelector.selectedSegmentIndex) {
            
        case 0: // CASE SLIDE
            coverView.retraction = MIN(1.0, MAX(0.0, 1.0 - ((2*nY-1.0) + 0.5)));
            break;
            
            
        case 1: // ATTENUATION
            // x = linear, y = quad
            if (touchIdx == 0) {
                attnLin = nX*20;
                attnQuad = nY*20;
                [coverView setUniform:@"u_attnLinear" withFloat:attnLin];
                [coverView setUniform:@"u_attnQuad" withFloat:attnQuad];
                
            }
            // x = const
            else if (touchIdx == 1) {
                attnConst = nY*20;
                [coverView setUniform:@"u_attnConst" withFloat:attnConst];
            }
            break;
            
            
        case 2: // LIGHT1

            // Touch 1 = XY, touch 2 Z (along Y)
            if (touchIdx == 0) {
                light0X = (2*nX - 1) * 6;       // let it go out to +-6
                light0Y = (2*nY - 1) * 6;
            }
            else if (touchIdx == 1) {
                light0Z = nY * 3 - 3.0;     // 0...-3
            }
            
            [coverView setUniform:@"u_light0Pos" withVec4:GLKVector4Make(light0X, light0Y, light0Z, 0.0)];
            break;
            
            
        case 3: // INTENSITIES & SPLIT FACTOR
            
            if (touchIdx == 0) {
                diffInts = nX * 10;
                specInts = nY * 20;
                [coverView setUniform:@"u_diffuseIntensity" withFloat:diffInts];
                [coverView setUniform:@"u_specularIntensity" withFloat:specInts];
                
            } else if (touchIdx == 1) {
                edgeFaceSplit = nY * 15; // 0..15
                [coverView setUniform:@"u_edgeFaceSplitFactor" withFloat:edgeFaceSplit];
                ;
            }
            
            break;
            
            
        case 4: // SPECULAR SHININESS
            
            if (touchIdx == 0) {
                shine = nY * 30;
                [coverView setUniform:@"u_shininess" withFloat:shine];
            }
            else if (touchIdx == 1) {
                ;
            }
            break;
    }
    [self _updateConsole];
}

//---------------------------------------------------------------------

- (void)_updateConsole
{
    _console.text = @"";
    [self _console:[NSString stringWithFormat:@"Attn: C=%.2f\tL=%.2f\tQ=%.2f", attnConst, attnLin, attnQuad]];
    [self _console:[NSString stringWithFormat:@"L0: (%.2f, %.2f, %.2f)", light0X, light0Y, light0Z]];
    
    [self _console:[NSString stringWithFormat:@"I: D=%.2f  S=%.2f  SPLIT=%.1f", diffInts, specInts, edgeFaceSplit]];

    [self _console:[NSString stringWithFormat:@"SHINE: %.2f", shine]];
   
}

//---------------------------------------------------------------------

- (void)_console:(NSString *)theText
{
    _console.text = [[_console.text stringByAppendingString:theText] stringByAppendingString:@"\n"];
    CGPoint offsetPoint = CGPointMake(0.0, _console.contentSize.height - _console.bounds.size.height);
   // [_console setContentOffset:offsetPoint animated:NO];
}

#endif
                               





@end
