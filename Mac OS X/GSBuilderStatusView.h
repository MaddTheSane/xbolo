//
//  GSBuilderStatusView.h
//  XBolo
//
//  Created by Robert Chrzanowski on 11/12/04.
//  Copyright 2004 Robert Chrzanowski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(int, GSBuilderStatusViewState) {
  GSBuilderStatusViewStateReady,
  GSBuilderStatusViewStateDirection,
  GSBuilderStatusViewStateDead,
};

@interface GSBuilderStatusView : NSView {
  GSBuilderStatusViewState state;
  CGFloat dir;
}

@property (nonatomic) GSBuilderStatusViewState state;
@property (nonatomic) CGFloat dir;

@end
