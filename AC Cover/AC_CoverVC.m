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

@implementation AC_CoverVC
{
    AC_CoverEmblemView *_emblemView;
    CMMotionManager *_motionManager;
    
    CADisplayLink *_updater;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _motionManager = [[CMMotionManager alloc] init];
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];

    [(AC_CoverView *)self.view setup];

    _emblemView = [AC_CoverEmblemView coverEmblemViewWithMotionManager:_motionManager];

    [_emblemView setCenter:self.view.center];
    [self.view addSubview:_emblemView];
    
    
    _updater = [CADisplayLink displayLinkWithTarget:self selector:@selector(_updateWithSender:)];
    [_updater addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)_updateWithSender:(id)sender
{
    [_emblemView setNeedsDisplay];
}
                               
                               





@end
