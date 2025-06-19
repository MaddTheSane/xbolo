#import "GSBoloDrawRectView.h"
#import "GSXBoloController.h"

#include "tiles.h"
#include "images.h"
#include "vector.h"
#include "rect.h"
#include "list.h"
#include "bolo.h"
#include "server.h"
#include "client.h"
#include "errchk.h"

#include <Carbon/Carbon.h>
#include <pthread.h>
#include <math.h>
#include <tgmath.h>

@import SpriteKit;

static NSImage *tiles = nil;
static NSImage *sprites = nil;
static NSCursor *cursor = nil;
static int dirtytiles(struct ListNode *list, GSRect rect);

/** Round the bytesPerRow to the best performance value */
size_t RoundBytesPerRow(size_t bytesPerRow) {
  bytesPerRow += 16 - bytesPerRow % 16;
  return bytesPerRow;
}

@interface GSBoloDrawRectView () {
  NSBitmapImageRep *_bestTiles;
  CGFloat _tilesScale;
  CGFloat _zoom;
}

- (void)drawTileAtPoint:(GSPoint)point;
- (void)drawTilesInRect:(NSRect)rect;
- (void)eraseSprites;
- (void)refreshTiles;
- (void)drawSprites;
- (void)drawSprite:(int)tile at:(Vec2f)point fraction:(CGFloat)fraction;
- (void)drawLabel:(const char *)label at:(Vec2f)point withAttributes:(NSDictionary<NSAttributedStringKey, id> *)attr;
- (void)drawString:(NSString *)label at:(Vec2f)point withAttributes:(NSDictionary<NSAttributedStringKey, id> *)attr;
- (void)dirtyTiles:(NSRect)rect;
@end

@implementation GSBoloDrawRectView

@synthesize boloController;

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    assert((tiles = [NSImage imageNamed:@"Tiles"]) != nil);
    assert((sprites = [NSImage imageNamed:@"Sprites"]) != nil);
    assert((cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"Cursor"] hotSpot:NSMakePoint(8.0, 8.0)]) != nil);
  });
}

- (instancetype)initWithFrame:(NSRect)frameRect {
TRY
  if (self = [super initWithFrame:frameRect]) {
    if (initlist(&rectlist) == -1) LOGFAIL(errno)

    _zoom = 1.0;
  }

CLEANUP
  switch (ERROR) {
    case 0:
      RETURN(self)

    default:
      PCRIT(ERROR)
      printlineinfo();
      CLEARERRLOG
      exit(EXIT_FAILURE);
  }
END
}

- (void)reset {
  /* NOOP */
}

- (void)refresh {
//    [view eraseSprites];
//    [view refreshTiles];
//    [view drawSprites];
  [self setNeedsDisplayInRect:self.visibleRect];
}

- (void)nextPillCenter {
  GSPoint square;
  NSRect rect;
  int i, j;

TRY
  rect = self.visibleRect;
  square.x = (rect.origin.x + rect.size.width*0.5)/16.0;
  square.y = FWIDTH - ((rect.origin.y + rect.size.height*0.5)/16.0);

  for (i = 0; i < client.npills; i++) {
    if (
        client.pills[i].owner == client.player &&
        client.pills[i].armour != ONBOARD && client.pills[i].armour != 0 &&
        square.x == client.pills[i].x && square.y == client.pills[i].y
        ) {
      for (j = (i + 1)%client.npills; j != i; j = (j + 1)%client.npills) {
        if (
            client.pills[j].owner == client.player &&
            client.pills[j].armour != ONBOARD && client.pills[j].armour != 0
            ) {
          square.x = client.pills[j].x;
          square.y = client.pills[j].y;
          rect.origin.x = ((square.x + 0.5)*16.0) - rect.size.width*0.5;
          rect.origin.y = ((FWIDTH - (square.y + 0.5))*16.0) - rect.size.height*0.5;
          SUCCESS
        }
      }

      square.x = client.pills[i].x;
      square.y = client.pills[i].y;
      rect.origin.x = ((square.x + 0.5)*16.0) - rect.size.width*0.5;
      rect.origin.y = ((FWIDTH - (square.y + 0.5))*16.0) - rect.size.height*0.5;
      SUCCESS
    }
  }

  for (i = 0; i < client.npills; i++) {
    if (
        client.pills[i].owner == client.player &&
        client.pills[i].armour != ONBOARD && client.pills[i].armour != 0
        ) {
      square.x = client.pills[i].x;
      square.y = client.pills[i].y;
      rect.origin.x = ((square.x + 0.5)*16.0) - rect.size.width*0.5;
      rect.origin.y = ((FWIDTH - (square.y + 0.5))*16.0) - rect.size.height*0.5;
      SUCCESS
    }
  }

CLEANUP
  switch (ERROR) {
    case 0:
      [self scrollRectToVisible:rect];
      break;

    default:
      PCRIT(ERROR)
      printlineinfo();
      CLEARERRLOG
      exit(EXIT_FAILURE);
      break;
  }
END
}

- (void)scroll:(CGPoint)delta {
  NSScreen *screen;
  NSRect rect;
  NSPoint nspoint;
  CGPoint cgpoint;

  rect = self.visibleRect;
  rect.origin = NSMakePoint(rect.origin.x + delta.x, rect.origin.y + delta.y);
  [self scrollRectToVisible:rect];

  nspoint = [NSEvent mouseLocation];
  if ([self mouse:[self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:self.window.contentView] inRect:self.visibleRect] && (screen = self.window.screen)) {
    cgpoint.x = nspoint.x;
    cgpoint.y = screen.frame.size.height - nspoint.y + 64.0;
    CGWarpMouseCursorPosition(cgpoint);
  }
}

- (void)scrollToVisible:(Vec2f)point {
  NSRect rect;
  rect.size.width = rect.size.height = 16 * 16 * _zoom;
  rect.origin.x = ((client.players[client.player].tank.x + 0.5)*16.0) - rect.size.width*0.5;
  rect.origin.y = ((FWIDTH - (client.players[client.player].tank.y + 0.5))*16.0) - rect.size.height*0.5;

  [self scrollRectToVisible:rect];
}

- (void)zoomTo:(CGFloat)zoom {
  _zoom = zoom;
  
  NSRect visRect = self.visibleRect;
  NSSize size;
  size.width = 4096.0*zoom;
  size.height = 4096.0*zoom;
  [self setFrameSize:size];
  [self setBoundsSize:NSMakeSize(4096.0, 4096.0)];
  [self scrollPoint:NSMakePoint(visRect.origin.x + 0.25*visRect.size.width, visRect.origin.y + 0.25*visRect.size.height)];
  [self setNeedsDisplay:YES];
}

- (void)tankCenter {
  NSRect rect;

TRY
  rect = self.visibleRect;

  rect.origin.x = ((client.players[client.player].tank.x + 0.5)*16.0) - rect.size.width*0.5;
  rect.origin.y = ((FWIDTH - (client.players[client.player].tank.y + 0.5))*16.0) - rect.size.height*0.5;

  [self scrollRectToVisible:rect];

CLEANUP
  switch (ERROR) {
    case 0:
      break;

    default:
      PCRIT(ERROR)
      printlineinfo();
      CLEARERRLOG
      exit(EXIT_FAILURE);
      break;
  }
END
}

- (void)makeTilesImage {
  NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
  CGContextRef bctx = ctx.CGContext;

  const CGFloat scale = self.window.screen.backingScaleFactor;
  const CGSize imageSize = CGSizeMake(tiles.size.width * scale, tiles.size.height * scale);

  const size_t bytesPerSample = CGBitmapContextGetBytesPerRow(bctx) / CGBitmapContextGetWidth(bctx);
  const size_t bytesPerRow = RoundBytesPerRow(bytesPerSample * imageSize.width);

  CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, CGBitmapContextGetBitsPerComponent(bctx), bytesPerRow, CGBitmapContextGetColorSpace(bctx), CGBitmapContextGetBitmapInfo(bctx));

  [NSGraphicsContext saveGraphicsState];
  NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:bitmapContext flipped:NO];
  [NSGraphicsContext setCurrentContext:graphicsContext];

  [tiles drawInRect:NSMakeRect(0, 0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext))];

  [graphicsContext flushGraphics];
  [NSGraphicsContext restoreGraphicsState];

  CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:image];
  CGImageRelease(image);
  CGContextRelease(bitmapContext);

  _bestTiles = rep;
  _tilesScale = scale;
}

- (void)drawRect:(NSRect)rect {
  if (_bestTiles == nil) {
    [self makeTilesImage];
  }

  BOOL gotlock = 0;

TRY
  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  [self drawTilesInRect:rect];
  [self drawSprites];

  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

CLEANUP
  switch (ERROR) {
  case 0:
    return;

  default:
    if (gotlock) {
      unlockclient();
    }

    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
  }
END
}

- (void)drawTileAtPoint:(GSPoint)point {
  if (NSGraphicsContext.currentContext == nil) {
    //*Headtilts* I don't know how...
    return;
  }
  GSImage image;
  NSRect dstRect, srcRect;

  image = client.images[point.y][point.x];
  dstRect = NSMakeRect(16.0*point.x, 16.0*(255 - point.y), 16.0, 16.0);
  srcRect = NSMakeRect((image%16)*16 * _tilesScale, (image/16)*16 * _tilesScale, 16.0 * _tilesScale, 16.0 * _tilesScale);

  /* draw tile */
  if (image == UNKNOWNIMAGE) {
    /* draw black */
    [[NSColor blackColor] set];
    [NSBezierPath fillRect:dstRect];
  }
  else {
    /* draw image */
    [_bestTiles drawInRect:dstRect fromRect:srcRect operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:NO hints:nil];

    /* draw mine */
    if (isMinedTile(client.seentiles, point.x, point.y)) {
      NSRect mineImageRect;

      mineImageRect = NSMakeRect((MINE00IMAGE%16)*16 * _tilesScale, (MINE00IMAGE/16)*16 * _tilesScale, 16.0 * _tilesScale, 16.0 * _tilesScale);
      [_bestTiles drawInRect:dstRect fromRect:mineImageRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:NO hints:nil];
    }

    /* draw fog */
    if (client.fog[point.y][point.x] <= 0) {
      [[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
      [NSBezierPath fillRect:dstRect];
    }
  }
}

- (void)drawTilesInRect:(NSRect)rect {
  int min_i, max_i, min_j, max_j;
  int min_x, max_x, min_y, max_y;
  int y, x;
  NSRect dstRect, srcRect;

  min_i = ((int)floor(NSMinX(rect)))/16;
  max_i = ((int)ceil(NSMaxX(rect)))/16;

  min_j = ((int)floor(NSMinY(rect)))/16;
  max_j = ((int)ceil(NSMaxY(rect)))/16;

  min_x = min_i;
  max_x = max_i;

  min_y = WIDTH - max_j;
  max_y = WIDTH - min_j;

  /* draw the tiles in the rect */
  for (y = min_y; y <= max_y; y++) {
    for (x = min_x; x <= max_x; x++) {
      GSImage image;

      image = client.images[y][x];
      dstRect = NSMakeRect(16.0*x, 16.0*(255 - y), 16.0, 16.0);
      srcRect = NSMakeRect((image%16)*16 * _tilesScale, (image/16)*16 * _tilesScale, 16.0 * _tilesScale, 16.0 * _tilesScale);

      /* draw tile */
      if (image == UNKNOWNIMAGE) {
        /* draw black */
        [[NSColor blackColor] set];
        [NSBezierPath fillRect:dstRect];
      }
      else {
        /* draw image */
        [_bestTiles drawInRect:dstRect fromRect:srcRect operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:NO hints: nil];

        /* draw mine */
        if (isMinedTile(client.seentiles, x, y)) {
          NSRect mineImageRect;

          mineImageRect = NSMakeRect((MINE00IMAGE%16)*16 * _tilesScale, (MINE00IMAGE/16)*16 * _tilesScale, 16.0 * _tilesScale, 16.0 * _tilesScale);
          [_bestTiles drawInRect:dstRect fromRect:mineImageRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:NO hints:nil];
        }

        /* draw fog */
        if (client.fog[y][x] <= 0) {
          [[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
          [NSBezierPath fillRect:dstRect];
        }
      }
    }
  }
}

- (void)eraseSprites {
  struct ListNode *node;
  int min_x, max_x, min_y, max_y;
  int y, x;
  GSRect *rect;

//  [NSGraphicsContext saveGraphicsState];
//  [[NSGraphicsContext currentContext] setShouldAntialias:NO];

  for (node = nextlist(&rectlist); node != NULL; node = nextlist(node)) {
    if (NSGraphicsContext.currentContext == nil) {
      //*Headtilts* I don't know how...
      break;
    }
    rect = (GSRect *)ptrlist(node);

    min_x = GSMinX(*rect);
    max_x = GSMaxX(*rect);

    min_y = GSMinY(*rect);
    max_y = GSMaxY(*rect);

    for (y = min_y; y <= max_y; y++) {
      for (x = min_x; x <= max_x; x++) {
        [self drawTileAtPoint:GSMakePoint(x, y)];
      }
    }
  }

//  [NSGraphicsContext restoreGraphicsState];

  clearlist(&rectlist, free);
}

- (void)refreshTiles {
  struct ListNode *node;
  if (NSGraphicsContext.currentContext == nil) {
    //*Headtilts* I don't know how...
    return;
  }

//  [NSGraphicsContext saveGraphicsState];
//  [[NSGraphicsContext currentContext] setShouldAntialias:NO];

  for (node = nextlist(&client.changedtiles); node != NULL; node = nextlist(node)) {
    GSPoint *p;
    GSImage image;
    NSRect dstRect;
    NSRect srcRect;

    p = (GSPoint *)ptrlist(node);
    image = client.images[p->y][p->x];
    dstRect = NSMakeRect(16.0*p->x, 16.0*(255 - p->y), 16.0, 16.0);
    srcRect = NSMakeRect((image%16)*16 * _tilesScale, (image/16)*16 * _tilesScale, 16.0 * _tilesScale, 16.0 * _tilesScale);

    /* draw tile */
    if (client.images[p->y][p->x] == UNKNOWNIMAGE) {
      /* draw black */
      [[NSColor blackColor] set];
      [NSBezierPath fillRect:dstRect];
    }
    else {
      /* draw image */
      [_bestTiles drawInRect:dstRect fromRect:srcRect operation:NSCompositingOperationCopy fraction:1.0 respectFlipped:NO hints:nil];

      /* draw mine */
      if (isMinedTile(client.seentiles, p->x, p->y)) {
        NSRect mineImageRect;

        mineImageRect = NSMakeRect((MINE00IMAGE%16)*16 * _tilesScale, (MINE00IMAGE/16)*16 * _tilesScale, 16.0 * _tilesScale, 16.0 * _tilesScale);
        [_bestTiles drawInRect:dstRect fromRect:mineImageRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:NO hints:nil];
      }

      /* draw fog */
      if (client.fog[p->y][p->x] == 0) {
        [[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
        [NSBezierPath fillRect:dstRect];
      }
    }
  }

//  [NSGraphicsContext restoreGraphicsState];
}

- (void)drawSprites {
  int i;
  struct ListNode *node;
  char *string = NULL;

TRY

  /* draw builders */
  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected) {
      switch (client.players[i].builderstatus) {
      case kBuilderGoto:
      case kBuilderWork:
      case kBuilderWait:
      case kBuilderReturn:
        [self drawSprite:(client.players[client.player].seq/5)%2 ? BUILD0IMAGE : BUILD1IMAGE at:client.players[i].builder fraction:calcvis(client.players[i].builder)];
        break;

      default:
        break;
      }
    }
  }

  /* draw other players */
  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected && i != client.player && !client.players[i].dead) {
      float vis;

      vis = calcvis(client.players[i].tank);

      if
      (
        (client.players[client.player].alliance & (1 << i)) &&
        (client.players[i].alliance & (1 << client.player))
      ) {
        [self drawSprite:(client.players[i].boat ? FTKB00IMAGE : FTNK00IMAGE) + (((int)(client.players[i].dir/(kPif/8.0) + 0.5))%16) at:client.players[i].tank fraction:vis];
      }
      else {
        [self drawSprite:(client.players[i].boat ? ETKB00IMAGE : ETNK00IMAGE) + (((int)(client.players[i].dir/(kPif/8.0) + 0.5))%16) at:client.players[i].tank fraction:vis];
      }

      if (vis > 0.90) {
        [self drawLabel:client.players[i].name at:client.players[i].tank withAttributes:@{NSForegroundColorAttributeName: [NSColor whiteColor]}];
      }
    }
  }

  /* draw player */
  if (!client.players[client.player].dead) {
    /* draw tank */
    [self drawSprite:(client.players[client.player].boat ? PTKB00IMAGE : PTNK00IMAGE) + (((int)(client.players[client.player].dir/(kPif/8.0) + 0.5))%16) at:client.players[client.player].tank fraction:1.0];
  }

  /* draw shells */
  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected) {
      struct ListNode *node;

      for (node = nextlist(&client.players[i].shells); node != NULL; node = nextlist(node)) {
        struct Shell *shell;

        shell = ptrlist(node);
        [self drawSprite:SHELL0IMAGE + (((int)(shell->dir/(kPif/8.0) + 0.5))%16) at:shell->point fraction:fogvis(shell->point)];
      }
    }
  }

  /* draw explosions */
  node = nextlist(&client.explosions);

  while (node != NULL) {
    struct Explosion *explosion;
    float f;

    explosion = ptrlist(node);
    f = ((float)explosion->counter)/EXPLOSIONTICKS;
    [self drawSprite:EXPLO0IMAGE + ((EXPLO5IMAGE - EXPLO0IMAGE)*f) at:explosion->point fraction:fogvis(explosion->point)];

    node = nextlist(node);
  }

  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected) {
      node = nextlist(&client.players[i].explosions);

      while (node != NULL) {
        struct Explosion *explosion;
        float f;

        explosion = ptrlist(node);
        f = ((float)explosion->counter)/EXPLOSIONTICKS;
        [self drawSprite:EXPLO0IMAGE + ((EXPLO5IMAGE - EXPLO0IMAGE)*f) at:explosion->point fraction:fogvis(explosion->point)];

        node = nextlist(node);
      }
    }
  }

  /* draw parachuting builders */
  for (i = 0; i < MAX_PLAYERS; i++) {
    if (client.players[i].connected) {
      if (client.players[i].builderstatus == kBuilderParachute) {
        [self drawSprite:BUILD2IMAGE at:client.players[i].builder fraction:fogvis(client.players[i].builder)];
      }
    }
  }

  /* draw selector */
  {
    NSPoint aPoint;
    aPoint = [self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:nil];
    if ([self mouse:aPoint inRect:self.visibleRect]) {
      [self drawSprite:SELETRIMAGE at:make2f(floor(aPoint.x/16.0) + 0.5, floor(FWIDTH - ((aPoint.y + 0.5)/16.0)) + 0.5) fraction:1.0];
    }
  }

  /* draw crosshair */
  if (!client.players[client.player].dead) {
    [self drawSprite:CROSSHIMAGE at:add2f(client.players[client.player].tank, mul2f(dir2vec(client.players[client.player].dir), client.range)) fraction:1.0];
  }

  if (client.pause) {
    NSRect rect;
    rect = self.visibleRect;

    if (client.pause == -1) {
      [self drawString:@"Paused" at:make2f((rect.origin.x + rect.size.width*0.5)/16.0, (256.0*16.0 - (rect.origin.y + rect.size.height*0.5))/16.0) withAttributes:@{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:90], NSForegroundColorAttributeName: [NSColor whiteColor]}];
    }
    else {
      if (asprintf(&string, "Resume in %d", client.pause) == -1) LOGFAIL(errno)
      [self drawLabel:string at:make2f((rect.origin.x + rect.size.width*0.5)/16.0, (256.0*16.0 - (rect.origin.y + rect.size.height*0.5))/16.0) withAttributes:@{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:90], NSForegroundColorAttributeName: [NSColor whiteColor]}];
      free(string);
      string = NULL;
    }
  }

CLEANUP
  switch (ERROR) {
  case 0:
    return;

  default:
    if (string) {
      free(string);
    }

    PCRIT(ERROR);
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
  }
END
}

- (void)drawSprite:(int)tile at:(Vec2f)point fraction:(CGFloat)fraction {
  NSRect srcRect;
  NSRect dstRect;

  if (fraction > 0.00001) {
    srcRect = NSMakeRect((tile%16)*16, (tile/16)*16, 16.0, 16.0);
    dstRect = NSMakeRect(floor(point.x*16.0 - 8.0), floor((FWIDTH - point.y)*16.0 - 8.0), 16.0, 16.0);
    if (NSGraphicsContext.currentContext != nil) {
      //*Headtilts* I don't know how...
      [sprites drawInRect:dstRect fromRect:srcRect operation:NSCompositingOperationSourceOver fraction:fraction];
    }
    [self dirtyTiles:dstRect];
  }
}

- (void)drawLabel:(const char *)label at:(Vec2f)point withAttributes:(NSDictionary<NSAttributedStringKey, id> *)attr {
  NSString *string = @(label);
  
  [self drawString:string at:point withAttributes:attr];
}

- (void)drawString:(NSString *)string at:(Vec2f)point withAttributes:(NSDictionary<NSAttributedStringKey, id> *)attr {
  NSRect rect;

  rect.size = [string sizeWithAttributes:attr];
  rect.origin.x = point.x*16.0 - rect.size.width*0.5;
  rect.origin.y = FWIDTH*16.0 - point.y*16.0 + 8.0;
  [string drawInRect:rect withAttributes:attr];
  [self dirtyTiles:rect];
}

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
    [boloController mouseEvent:GSMakePoint(point.x/16.0, 255 - (int)(point.y/16.0))];
  }
}

- (BOOL)isOpaque {
  return YES;
}

- (void)dirtyTiles:(NSRect)rect {
  GSRect GSRect;

TRY
  GSRect.origin.x = NSMinX(rect)/16.0;
  GSRect.origin.y = NSMinY(rect)/16.0;
  GSRect.size.width = ((int)((NSMaxX(rect) + 16.0)/16.0)) - GSRect.origin.x;
  GSRect.size.height = ((int)((NSMaxY(rect) + 16.0)/16.0)) - GSRect.origin.y;
  GSRect.origin.y = WIDTH - (GSRect.origin.y + GSRect.size.height);

  if (dirtytiles(&rectlist, GSRect)) LOGFAIL(errno)

CLEANUP
  switch (ERROR) {
  case 0:
    return;

  default:
    PCRIT(ERROR);
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
  }
END
}

- (void)resetCursorRects {
	[self addCursorRect:self.visibleRect cursor:cursor];
  [cursor setOnMouseEntered:YES];
}

@end

int dirtytiles(struct ListNode *list, GSRect rect) {
  GSRect *rectptr = NULL;
  struct ListNode *node = NULL;

TRY
  if (GSIsEmptyRect(rect)) {
    SUCCESS
  }

  for (node = nextlist(list); node != NULL; node = nextlist(node)) {
    GSRect *oldrect;

    oldrect = ptrlist(node);

    if (GSIntersectsRect(*oldrect, rect)) {
      if (GSContainsRect(rect, *oldrect)) {
        *oldrect = rect;
      }
      else if (!GSContainsRect(*oldrect, rect)) {
        GSRect rectsub[4];
        int i;

        GSSubtractRect(rect, *oldrect, rectsub);

        for (i = 0; i < 4; i++) {
          if (dirtytiles(node, rectsub[i])) LOGFAIL(errno)
        }
      }

      break;
    }
  }

  if (node == NULL) {
    if ((rectptr = (GSRect *)malloc(sizeof(GSRect))) == NULL) LOGFAIL(errno)
    *rectptr = rect;
    if (addlist(list, rectptr) == -1) LOGFAIL(errno)
    rectptr = NULL;
  }

CLEANUP
  switch (ERROR) {
  case 0:
    RETURN(0)

  default:
    if (rectptr) {
      free(rectptr);
    }

    RETERR(-1)
  }
END
}
