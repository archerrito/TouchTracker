//
//  BNRDrawViewController.m
//  TouchTracker
//
//  Created by Archer on 6/10/14.
//  Copyright (c) 2014 Oodalalee. All rights reserved.
//

#import "BNRDrawViewController.h"
#import "BNRDrawView.h"

@implementation BNRDrawViewController

- (void)loadView
{
    self.view = [[BNRDrawView alloc] initWithFrame:CGRectZero];
}

@end
