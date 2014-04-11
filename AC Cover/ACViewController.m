//
//  ACViewController.m
//  AC Cover
//
//  Created by Hari Karam Singh on 11/04/2014.
//  Copyright (c) 2014 Air Craft. All rights reserved.
//

#import "ACViewController.h"
#import "AC_CoverView.h"


@implementation ACViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [(AC_CoverView *)self.view setup];
}

- (void)dealloc
{    
}

#pragma mark -  OpenGL ES 2 shader compilation




@end
