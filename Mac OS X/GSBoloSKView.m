//
//  GSBoloSKView.m
//  Mac OS X
//
//  Created by Karl von Randow on 30/05/19.
//  Copyright © 2019 Karl von Randow. All rights reserved.
//

#import "GSBoloSKView.h"

#import "GSXBoloController.h"
#import "GSBoloScene.h"

#import "bolo.h"
#import "images.h"
#import "client.h"

#include <Carbon/Carbon.h>

static NSCursor *cursor = nil;

@interface GSBoloSKView() {
  GSBoloScene *_scene;
  id<NSObject> _boundsChangeObserver;
}

- (void)boundsDidChange;

@end

@implementation GSBoloSKView

@synthesize boloController;

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    assert((cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"Cursor"] hotSpot:NSMakePoint(8.0, 8.0)]) != nil);
  });
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    self.showsFPS = YES;
    self.showsNodeCount = YES;
    self.preferredFramesPerSecond = 16;
    self.ignoresSiblingOrder = YES;
    self.shouldCullNonVisibleNodes = YES;

    self.postsBoundsChangedNotifications = YES;
    __weak typeof(self) weakSelf = self;
    _boundsChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self queue:nil usingBlock:^(NSNotification * _Nonnull note) {
      [weakSelf boundsDidChange];
    }];

    _scene = [[GSBoloScene alloc] initWithSize:frameRect.size];
    [self presentScene:_scene];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:_boundsChangeObserver];
  _boundsChangeObserver = nil;
}

- (void)boundsDidChange {
  [_scene setSize:self.bounds.size];
}

- (void)reset {
  _scene = [[GSBoloScene alloc] initWithSize:self.bounds.size];
  [self presentScene:_scene];
}

- (void)refresh {
  [_scene update];
}

- (void)scroll:(CGPoint)delta {
  [_scene scroll:delta];
}

- (void)scrollToVisible:(Vec2f)point {
  [_scene scrollToVisible:point];
}

- (void)zoomTo:(CGFloat)zoom {
  [_scene zoomTo:zoom];
}

- (void)tankCenter {
  [_scene tankCenter];
}

- (void)nextPillCenter {
  [_scene nextPillCenter];
}

#pragma mark -

- (BOOL)becomeFirstResponder {
  BOOL okToChange;
  if ((okToChange = [super becomeFirstResponder])) {
    modifiers =
    [NSEvent modifierFlags] & (NSEventModifierFlagCapsLock | NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand | NSEventModifierFlagNumericPad);
    //    (carbonModifiers &  ? NSHelpKeyMask : 0) |
    //    (carbonModifiers &  ? NSFunctionKeyMask : 0);
  }
  return okToChange;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
  if (!theEvent.ARepeat) {
    [boloController keyEvent:YES forKey:theEvent.keyCode];
  }
}

- (void)keyUp:(NSEvent *)theEvent {
  if (!theEvent.ARepeat) {
    [boloController keyEvent:NO forKey:theEvent.keyCode];
  }
}

- (void)flagsChanged:(NSEvent *)theEvent {
  NSEventModifierFlags oldModifiers;
  oldModifiers = modifiers;
  modifiers = theEvent.modifierFlags & (NSEventModifierFlagCapsLock | NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand | NSEventModifierFlagNumericPad | NSEventModifierFlagHelp | NSEventModifierFlagFunction);
  if (modifiers & (oldModifiers ^ modifiers)) {
    [boloController keyEvent:YES forKey:theEvent.keyCode];
  }
  else {
    [boloController keyEvent:NO forKey:theEvent.keyCode];
  }
}

- (void)mouseUp:(NSEvent *)theEvent {
  if (theEvent.type == NSEventTypeLeftMouseUp) {
    NSPoint point;

    point = [self convertPoint:theEvent.locationInWindow fromView:nil];
    point = [_scene convertPointFromView:point];
    [boloController mouseEvent:GSMakePoint(point.x/16.0, WIDTH - (int)(point.y/16.0) - 1)];
  }
}

- (BOOL)isOpaque {
  return YES;
}

- (void)resetCursorRects {
  [self addCursorRect:self.visibleRect cursor:cursor];
  [cursor setOnMouseEntered:YES];
}

@end
