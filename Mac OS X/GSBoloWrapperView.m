//
//  GSBoloWrapperView.m
//  Mac OS X
//
//  Created by Karl von Randow on 1/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

#import "GSBoloWrapperView.h"

#import "GSBoloMTKView.h"
#import "GSBoloSKView.h"
#import "GSBoloDrawRectView.h"
#import "GSBoloViews.h"

@interface GSBoloWrapperView() {
  id<GSBoloViewProtocol> _wrapped;
  NSScrollView *_scrollView;
  id<NSObject> _boundsChangeObserver;
}

- (void)boundsDidChange;

@end

@implementation GSBoloWrapperView

@synthesize boloController = boloController;

- (instancetype)initWithFrame:(NSRect)frameRect {
  if (self = [super initWithFrame:frameRect]) {
    self.postsBoundsChangedNotifications = YES;
    __weak typeof(self) weakSelf = self;
    _boundsChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:self queue:nil usingBlock:^(NSNotification * _Nonnull note) {
      [weakSelf boundsDidChange];
    }];
  }

  return self;
}

- (void)createWrappedView {
  // Remove existing view
  if (_wrapped) {
    [(NSView *)_wrapped removeFromSuperview];
    [GSBoloViews removeView:_wrapped];
    _wrapped = nil;
  }

  // Create bolo view
  if (@available(macOS 10.13, *)) {
    if ([GSBoloMTKView canUseMetal]) {
      _wrapped = [[GSBoloMTKView alloc] initWithFrame:self.bounds];
      [self addSubview:(NSView *)_wrapped];
    }
  }

  if (!_wrapped) {
    if (@available(macOS 10.12, *)) {
      _wrapped = [[GSBoloSKView alloc] initWithFrame:self.bounds];
      [self addSubview:(NSView *)_wrapped];
    } else {
      NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
      _wrapped = [[GSBoloDrawRectView alloc] initWithFrame:NSMakeRect(0, 0, 4096, 4096)];
      NSView *wrappedView = (NSView *)_wrapped;
      scrollView.documentView = wrappedView;
      [self addSubview:scrollView];
      _scrollView = scrollView;
    }
  }

  _wrapped.boloController = boloController;
  [GSBoloViews addView:_wrapped];
}

- (void)boundsDidChange {
  if (_scrollView) {
    _scrollView.frame = self.bounds;
  } else {
    ((NSView *)_wrapped).frame = self.bounds;
  }
}

- (void)nextPillCenter {
  [_wrapped nextPillCenter];
}

- (void)reset {
  [self createWrappedView];
  [_wrapped reset];
}

- (void)refresh {
  [_wrapped refresh];
}

- (void)scroll:(CGPoint)delta {
  [_wrapped scroll:delta];
}

- (void)scrollToVisible:(Vec2f)point {
  [_wrapped scrollToVisible:point];
}

- (void)zoomTo:(CGFloat)zoom {
  [_wrapped zoomTo:zoom];
}

- (void)tankCenter {
  [_wrapped tankCenter];
}

@end
