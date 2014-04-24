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
#pragma mark -
/////////////////////////////////////////////////////////////////////////

@interface AC_CoverVC()
{
    __weak IBOutlet UISegmentedControl *_paramSelector;
    __weak IBOutlet UILabel *_consoleLbl;
}

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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _activeTouches = NSMutableArray.array;
    
    _motionManager = [[CMMotionManager alloc] init];
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];

    [(AC_CoverView *)self.view setup];

    _emblemView = [AC_CoverEmblemView coverEmblemViewWithMotionManager:_motionManager];

    [_emblemView setCenter:self.view.center];
    [self.view addSubview:_emblemView];
    
    
    _updater = [CADisplayLink displayLinkWithTarget:self selector:@selector(_updateWithSender:)];
    [_updater addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    [self _updateConsole];
}

- (void)_updateWithSender:(id)sender
{
    [_emblemView setNeedsDisplay];
}


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
    
    switch (_paramSelector.selectedSegmentIndex) {
            
        case 0: // CASE SLIDE
            coverView.retraction = 1.0 - nY;
            break;
            
            
        case 1: // LIGHT0
            
            // Touch 1 = position, touch 2 intensity (along X)
            if (touchIdx == 0)
                coverView.light0Position = pt;
            else if (touchIdx == 1)
                coverView.light0Intensity = nY;
            break;
            
            
        case 2: // LIGHT1

            // Touch 1 = position, touch 2 intensity (along X)
            if (touchIdx == 0)
                coverView.light1Position = pt;
            else if (touchIdx == 1)
                coverView.light1Intensity = nY;
            break;
            
            
        case 3: // FACE
            
            if (touchIdx == 0)
                coverView.faceDiffuse = nX;
            else if (touchIdx == 1)
                coverView.faceSpecular = nY;
            break;
            
            
        case 4: // EDGE
            
            if (touchIdx == 0)
                coverView.edgeDiffuse = nX;
            else if (touchIdx == 1)
                coverView.edgeSpecular = nY;
            break;
    }
    
    [self _updateConsole];
}


//---------------------------------------------------------------------

- (void)_updateConsole
{
    AC_CoverView *coverView = (AC_CoverView *)self.view;

    _consoleLbl.text = [NSString stringWithFormat:
                        @" L0:\tp(%.2f, %.2f,)\ti(%.2f)\n"
                         " L1:\tp(%.2f, %.2f,)\ti(%.2f)\n"
                         " FACE:\td(%.2f)\ts(%.2f)\n"
                         " EDGE:\td(%.2f)\ts(%.2f)",
                        
                        coverView.light0Position.x,
                        coverView.light0Position.y,
                        coverView.light0Intensity,
                        
                        coverView.light1Position.x,
                        coverView.light1Position.y,
                        coverView.light1Intensity,
                        
                        coverView.faceDiffuse,
                        coverView.faceSpecular,
                        
                        coverView.edgeDiffuse,
                        coverView.edgeSpecular];
}
                               
                               





@end
