//
//  BNRDrawView.m
//  TouchTracker
//
//  Created by Archer on 6/10/14.
//  Copyright (c) 2014 Oodalalee. All rights reserved.
//

#import "BNRDrawView.h"
#import "BNRLine.h"

@interface BNRDrawView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;
@property (nonatomic, strong) NSMutableDictionary *linesInProgress;
@property (nonatomic, strong) NSMutableArray *finishedLines;

@property (nonatomic, weak) BNRLine *selectedLine;

@end

@implementation BNRDrawView

- (instancetype)initWithFrame:(CGRect)r
{
    self = [super initWithFrame:r];
    
    if (self) {
        self.linesInProgress = [[NSMutableDictionary alloc] init];
        self.finishedLines = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor grayColor];
        self.multipleTouchEnabled = YES;
        
        UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.delaysTouchesBegan = YES;
        
        [self addGestureRecognizer:doubleTapRecognizer];
        
        UITapGestureRecognizer *tapRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        
        tapRecognizer.delaysTouchesBegan = YES;
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        
        [self addGestureRecognizer:tapRecognizer];
        
        UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        
        [self addGestureRecognizer:pressRecognizer];
        
        self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
        
        self.moveRecognizer.delegate = self;
        self.moveRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:self.moveRecognizer];
    }
    
    return self;
}

- (void)strokeLine:(BNRLine *)line
{
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

- (void)drawRect:(CGRect)rect
{
    //Draw finished lines in black
    [[UIColor blackColor] set];
    for (BNRLine *line in self.finishedLines) {
        [self strokeLine:line];
    }
    
    [[UIColor redColor] set];
    for (NSValue *key in self.linesInProgress) {
        [self strokeLine:self.linesInProgress[key]];
    }
    
    if (self.selectedLine) {
        [[UIColor greenColor] set];
        [self strokeLine:self.selectedLine];
    }
    
}

//Creates a new line
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //LEts put in a log statement to see the order of events
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        CGPoint location = [t locationInView:self];
        
        BNRLine *line = [[BNRLine alloc] init];
        line.begin = location;
        line.end = location;
        
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        self.linesInProgress[key] = line;
    }
    [self setNeedsDisplay];
}

//updates end of the current line
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    //Lets put in a log statement to see order of events
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        BNRLine *line = self.linesInProgress[key];
        
        line.end = [t locationInView:self];
    }
    
    [self setNeedsDisplay];
}

//Add curruentline to finishedlines when touche ends
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    //Log statement
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        BNRLine *line = self.linesInProgress[key];
        
        [self.finishedLines addObject:line];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    //Lets put in a log statement to see order
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}

- (void)doubleTap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized double tap");
    
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects] ;
    
    [self setNeedsDisplay];
}

-(void)tap:(UIGestureRecognizer *)gr
{
    NSLog(@"Recognized tap");
    
    CGPoint point = [gr locationInView:self];
    self.selectedLine = [self lineAtPoint:point];
    
    if (self.selectedLine) {
        
        //Make ourselves the target of menu item action messages
        [self becomeFirstResponder];
        
        //Grab the menu controller
        UIMenuController *menu = [UIMenuController sharedMenuController];
        
        //Create a new delete UIMenuItem
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine:)];
        menu.menuItems = @[deleteItem];
        
        //Tell the menu where it should come from and show it
        [menu setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    } else {
        //Hide menu if no line is selected
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    
    [self setNeedsDisplay];
}

- (BNRLine *)lineAtPoint:(CGPoint)p
{
    //Find a line close to p
    for (BNRLine *l in self.finishedLines) {
        CGPoint start = l.begin;
        CGPoint end = l.end;
        
        //chekc a few points on the line
        for (float t = 0.0; t <= 1.0; t += 0.05) {
            float x = start.x + t * (end.x -start.x);
            float y = start.y + t * (end.y - start.y);
            
            //If the tapped point is within 20 points, lets return this line
            if (hypot(x - p.x, y - p.y) < 20) {
                return l;
            }
        }
    }
    //If nothing is close enough to a tapped point, then we did not select a line
    return  nil;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)deleteLine:(id)sender
{
    //Remove the selected line from the list of _finishedLines
    [self.finishedLines removeObject:self.selectedLine];
    
    //Redraaw everything
    [self setNeedsDisplay];
}

- (void)longPress:(UIGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gr locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
        
        if (self.selectedLine) {
            [self.linesInProgress removeAllObjects];
        }
    } else if (gr.state == UIGestureRecognizerStateEnded) {
        self.selectedLine = nil;
    }
    [self setNeedsDisplay];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer ==self.moveRecognizer) {
        return  YES;
    }
    return  NO;
}

- (void)moveLine:(UIPanGestureRecognizer *)gr
{
    //If we have not selected a line, we do not do anything here
    if (!self.selectedLine) {
        return;
    }
    
    //When the pan recognizer changes its position
    if (gr.state == UIGestureRecognizerStateChanged) {
        //How far has the pan moved?
        CGPoint translation = [gr translationInView:self];
        
        //Add the translation to the current beginning and end points of the line
        CGPoint begin = self.selectedLine.begin;
        CGPoint end = self.selectedLine.end;
        begin.x += translation.x;
        begin.y += translation.y;
        end.x += translation.x;
        end.y += translation.y;
        
        //Set the new beginning and end points of the line
        self.selectedLine.begin = begin;
        self.selectedLine.end = end;
        
        //Redraw the screen
        [self setNeedsDisplay];
        
        [gr setTranslation:CGPointZero inView:self];
    }
}

- (int)numberOfLines
{
    int count = 0;
    
    //Check that they are non-nil before we add their counts...
    if (self.linesInProgress && self.finishedLines)
        count = [self.linesInProgress count] + [self.finishedLines count];
    
    return  count;
}

@end
