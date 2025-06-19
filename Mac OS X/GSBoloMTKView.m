//
//  GSBoloMTKView.m
//  Mac OS X
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Karl von Randow. All rights reserved.
//

#import "GSBoloMTKView.h"

#import "GSXBoloController.h"
#import "GSBoloScene.h"
#import "GSBoloMetalRenderer.h"

#import "bolo.h"
#import "images.h"
#import "client.h"

#include <Carbon/Carbon.h>

static NSCursor *cursor = nil;

@interface GSBoloMTKView() {
  GSBoloMetalRenderer *_renderer;
  id<NSObject> _deviceObserver;
}

@end

@implementation GSBoloMTKView

@synthesize boloController;

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    assert((cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"Cursor"] hotSpot:NSMakePoint(8.0, 8.0)]) != nil);
  });
}

+ (BOOL)canUseMetal {
  return MTLCopyAllDevices().count > 0;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect device:nil]) {
    [self chooseDevice];

    self.preferredFramesPerSecond = 16;
    self.framebufferOnly = YES;
  }
  return self;
}

- (void)viewDidMoveToWindow {
  _renderer = [[GSBoloMetalRenderer alloc] initWithMTLView:self];
  self.delegate = _renderer;
}

- (void)chooseDevice {
  id <NSObject> deviceObserver  = nil;
  NSArray<id<MTLDevice>> *deviceList = nil;
  __weak typeof(self) weakSelf = self;

  deviceList = MTLCopyAllDevicesWithObserver(&deviceObserver,
                                             ^(id<MTLDevice> device, MTLDeviceNotificationName name) {
                                               if ([name isEqualToString:MTLDeviceRemovalRequestedNotification] || [name isEqualToString:MTLDeviceWasRemovedNotification]) {
                                                 if (device == weakSelf.device) {
                                                   [weakSelf chooseDevice];
                                                 }
                                               }
                                             });
  id<MTLDevice> bestDevice = nil;
  for (id<MTLDevice> device in deviceList) {
    if (device.isLowPower) {
      NSLog(@"Choosing device %@", device);
      bestDevice = device;
    } else {
      NSLog(@"Skipping device %@", device);
    }
  }

  if (!bestDevice) {
    bestDevice = deviceList[0];
  }
  NSLog(@"Chosen device %@", bestDevice);
  self.device = bestDevice;

  if (_deviceObserver) {
    MTLRemoveDeviceObserver(_deviceObserver);
  }
  _deviceObserver = deviceObserver;
}

- (void)reset {
  [_renderer resetScene:self];
}

- (void)refresh {
  [_renderer.scene update];
}

- (void)scroll:(CGPoint)delta {
  [_renderer.scene scroll:delta];
}

- (void)scrollToVisible:(Vec2f)point {
  [_renderer.scene scrollToVisible:point];
}

- (void)zoomTo:(CGFloat)zoom {
  [_renderer.scene zoomTo:zoom];
}

- (void)tankCenter {
  [_renderer.scene tankCenter];
}

- (void)nextPillCenter {
  [_renderer.scene nextPillCenter];
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
    point = [_renderer.scene convertPointFromView:point];
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
