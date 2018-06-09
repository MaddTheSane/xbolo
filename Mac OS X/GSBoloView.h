#import <Cocoa/Cocoa.h>
#include "list.h"

@class NSImage;

@class GSXBoloController;

@interface GSBoloView : NSView {
  struct ListNode rectlist;

  IBOutlet GSXBoloController *boloController;
  NSEventModifierFlags modifiers;
}
+ (void)refresh;
+ (void)removeView:(GSBoloView *)view;
@end
