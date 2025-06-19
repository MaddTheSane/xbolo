#import "GSXBoloController.h"
#import "GSBoloViews.h"
#import "GSRobot.h"
#import "GSStatusBar.h"
#import "GSBuilderStatusView.h"
#import "GSKeyCodeField.h"
#import "GSBoloViews.h"
#import "XBoloBonjour.h"

#include "bolo.h"
#include "server.h"
#include "client.h"
#include "resolver.h"
#include "tracker.h"
#include "errchk.h"

#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

typedef NS_ENUM(NSInteger, GSServerSource) {
  GSServerSourceTracker = 0,
  GSServerSourceBonjour
};

static NSString * const GSHostMap                    = @"GSHostMapString";
static NSString * const GSHostUPnP                   = @"GSHostUPnPBool";
static NSString * const GSHostPort                   = @"GSHostPortNumber";
static NSString * const GSHostUsePassword            = @"GSHostPasswordBool";
static NSString * const GSHostPassword               = @"GSHostPasswordString";
static NSString * const GSHostUseTimeLimit           = @"GSHostTimeLimitBool";
static NSString * const GSHostTimeLimit              = @"GSHostTimeLimitString";
static NSString * const GSHostHiddenMines            = @"GSHostHiddenMinesBool";
static NSString * const GSHostTracker                = @"GSHostTrackerBool";
static NSString * const GSHostGameType               = @"GSHostGameTypeNumber";
static NSString * const GSHostDominationType         = @"GSHostDominationTypeNumber";
static NSString * const GSHostDominationBaseControl  = @"GSHostDominationBaseControlString";
static NSString * const GSJoinAddress                = @"GSJoinAddressString";
static NSString * const GSJoinPort                   = @"GSJoinPortNumber";
static NSString * const GSJoinHasPassword            = @"GSJoinPasswordBool";
static NSString * const GSJoinPassword               = @"GSJoinPasswordString";
static NSString * const GSTracker                    = @"GSTrackerString";

static NSString * const GSPrefPaneIdentifier         = @"GSPrefPaneIdentifierString";
static NSString * const GSPlayerNameString           = @"GSPlayerNameString";
static NSString * const GSKeyConfigDict              = @"GSKeyConfigDict";
static NSString * const GSAutoSlowdown               = @"GSAutoSlowdownBool";
static NSString * const GSAccelerate                 = @"GSAccelerateString";
static NSString * const GSBrake                      = @"GSBrakeString";
static NSString * const GSTurnLeft                   = @"GSTurnLeftString";
static NSString * const GSTurnRight                  = @"GSTurnRightString";
static NSString * const GSLayMine                    = @"GSLayMineString";
static NSString * const GSShoot                      = @"GSShootString";
static NSString * const GSIncreaseAim                = @"GSIncreaseAimString";
static NSString * const GSDecreaseAim                = @"GSDecreaseAimString";
static NSString * const GSUp                         = @"GSUpString";
static NSString * const GSDown                       = @"GSDownString";
static NSString * const GSLeft                       = @"GSLeftString";
static NSString * const GSRight                      = @"GSRightString";
static NSString * const GSTankView                   = @"GSTankViewString";
static NSString * const GSPillView                   = @"GSPillViewString";

static NSString * const GSMute                       = @"GSMuteBool";

// bolo toolbar prefs
static NSString * const GSBuilderTool                = @"GSBuilderToolInteger";

//static NSString * const GSPlayerInfoImage            = @"PlayerInfo";
static NSImageName const GSKeyConfigImage             = @"KeyConfig";

static NSImageName const GSTankCenterImage            = @"TankCenter";
static NSImageName const GSPillCenterImage            = @"PillCenter";
static NSImageName const GSZoomInImage                = @"ZoomIn";
static NSImageName const GSZoomOutImage               = @"ZoomOut";

// toolbar item identifiers
static NSToolbarIdentifier const GSPreferencesToolbar               = @"GSPreferencesToolbar";
static NSToolbarItemIdentifier const GSToolbarPlayerInfoItemIdentifier  = @"GSToolbarPlayerInfoItemIdentifier";
static NSToolbarItemIdentifier const GSToolbarKeyConfigItemIdentifier   = @"GSToolbarKeyConfigItemIdentifier";

static NSToolbarIdentifier const GSBoloToolbar                      = @"GSBoloToolbar";
static NSToolbarItemIdentifier const GSZoomInItemIdentifier         = @"GSZoomInItemIdentifier";
static NSToolbarItemIdentifier const GSZoomOutItemIdentifier        = @"GSZoomOutItemIdentifier";
static NSToolbarItemIdentifier const GSBoloToolItemIdentifier       = @"GSBoloToolItemIdentifier";
static NSToolbarItemIdentifier const GSTankCenterItemIdentifier     = @"GSTankCenterItemIdentifier";
static NSToolbarItemIdentifier const GSPillCenterItemIdentifier     = @"GSPillCenterItemIdentifier";

static NSString * const GSShowStatus                       = @"GSShowStatusBool";
static NSString * const GSShowAllegiance                   = @"GSShowAllegianceBool";
static NSString * const GSShowMessages                     = @"GSShowMessagesBool";

// tracker table view columns
static NSUserInterfaceItemIdentifier const GSSourceColumn     = @"GSSourceColumn";
static NSUserInterfaceItemIdentifier const GSHostPlayerColumn = @"GSHostPlayerColumn";
static NSUserInterfaceItemIdentifier const GSMapNameColumn    = @"GSMapNameColumn";
static NSUserInterfaceItemIdentifier const GSPlayersColumn    = @"GSPlayersColumn";
static NSUserInterfaceItemIdentifier const GSPasswordColumn   = @"GSPasswordColumn";
static NSUserInterfaceItemIdentifier const GSAllowJoinColumn  = @"GSAllowJoinColumn";
static NSUserInterfaceItemIdentifier const GSPausedColumn     = @"GSPausedColumn";
static NSUserInterfaceItemIdentifier const GSHostnameColumn   = @"GSHostnameColumn";
static NSUserInterfaceItemIdentifier const GSPortColumn       = @"GSPortColumn";
#define GSNetServiceKey @"NetService"

// message panel
static NSString * const GSMessageTarget                   = @"GSMessageTarget";

// private settings
static NSString * const GSDisableBonjour                  = @"GSDisableBonjour";


static GSXBoloController *controller = nil;

// sound
static BOOL muteGlobal;

static NSMutableArray<NSSound*> *bubblessounds;
static NSMutableArray<NSSound*> *builderdeathsounds;
static NSMutableArray<NSSound*> *buildsounds;
static NSMutableArray<NSSound*> *sinksounds;
static NSMutableArray<NSSound*> *superboomsounds;
static NSMutableArray<NSSound*> *explosionsounds;
static NSMutableArray<NSSound*> *farbuildsounds;
static NSMutableArray<NSSound*> *farbuilderdeathsounds;
static NSMutableArray<NSSound*> *farexplosionsounds;
static NSMutableArray<NSSound*> *farhittanksounds;
static NSMutableArray<NSSound*> *farhitterrainsounds;
static NSMutableArray<NSSound*> *farhittreesounds;
static NSMutableArray<NSSound*> *farshotsounds;
static NSMutableArray<NSSound*> *farsinksounds;
static NSMutableArray<NSSound*> *farsuperboomsounds;
static NSMutableArray<NSSound*> *fartreesounds;
static NSMutableArray<NSSound*> *minesounds;
static NSMutableArray<NSSound*> *msgreceivedsounds;
static NSMutableArray<NSSound*> *pillshotsounds;
static NSMutableArray<NSSound*> *hittanksounds;
static NSMutableArray<NSSound*> *tankshotsounds;
static NSMutableArray<NSSound*> *hitterrainsounds;
static NSMutableArray<NSSound*> *hittreesounds;
static NSMutableArray<NSSound*> *treesounds;

static NSMutableArray<NSSpeechSynthesizer*> *speechSynthesizers;

static struct ListNode trackerlist;

static const CGFloat kZoomLevels[] = {
    0.5,
    0.75,
    1.0,
    1.5,
    2.0
};

#define DEFAULT_ZOOM 2
#define MAX_ZOOM (sizeof(kZoomLevels) / sizeof(*kZoomLevels) - 1)

// set the key
int setKey(NSMutableDictionary *dict, NSWindow *win, GSKeyCodeField *field, NSString *newObject);

static void registercallback(int status);
static void getlisttrackerstatus(int status);

@interface GSXBoloController ()

// bolo callbacks
- (void)setPlayerStatus:(NSString *)aString;
- (void)setPillStatus:(NSString *)aString;
- (void)setBaseStatus:(NSString *)aString;
- (void)setTankStatusBars;
- (void)refresh:(NSTimer *)aTimer;
- (void)printMessage:(NSAttributedString *)string;
- (void)setJoinProgressStatusTextField:(NSString *)aString;
- (void)setJoinProgressIndicator:(NSNumber *)aString;

// callbacks from client thread
- (void)joinSuccess;
- (void)joinDNSError:(NSString *)eString;
- (void)joinTimeOut;
- (void)joinConnectionRefused;
- (void)joinNetUnreachable;
- (void)joinHostUnreachable;
- (void)joinBadVersion;
- (void)joinDisallow;
- (void)joinBadPassword;
- (void)joinServerFull;
- (void)joinTimeLimit;
- (void)joinBannedPlayer;
- (void)joinServerError;
- (void)joinConnectionReset;

- (void)registerSuccess;

// callback for tracker dns error
- (void)trackerDNSError:(NSString *)eString;

// callbacks from registertracker
- (void)registerTrackerTimeOut;
- (void)registerTrackerConnectionRefused;
- (void)registerTrackerHostDown;
- (void)registerTrackerHostUnreachable;
- (void)registerTrackerBadVersion;
- (void)registerTrackerTCPPortBlocked;
- (void)registerTrackerUDPPortBlocked;
- (void)registerTrackerConnectionReset;

// callbacks from getlisttracker
- (void)getListTrackerTimeOut;
- (void)getListTrackerConnectionRefused;
- (void)getListTrackerHostDown;
- (void)getListTrackerHostUnreachable;
- (void)getListTrackerBadVersion;
- (void)getListTrackerSuccess;

// robots
- (BOOL)_validateRobotMenuItem: (NSMenuItem *)item;
- (void)setupRobotsMenu;

// misc
- (void)updateTableButtons:(NSTableView *)table;
@end

@implementation GSXBoloController {
  XBoloBonjour *broadcaster;
}

@synthesize joinAddress = joinAddressString;
@synthesize joinPort = joinPortNumber;
@synthesize hostPort = hostPortNumber;
@synthesize mute = muteBool;
@synthesize playerName = playerNameString;
@synthesize joinPasswordEnabled = joinPasswordBool;
@synthesize joinPassword = joinPasswordString;
@synthesize autoSlowdown = autoSlowdownBool;
@synthesize tracker = trackerString;

// NIB methods

- (void)awakeFromNib {
  NSUserDefaults *defaults;
  NSSound *sound;

  controller = self;
  defaults = [NSUserDefaults standardUserDefaults];
  [defaults registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultPreferences" ofType:@"plist"]]];

  // init toolbar items
  toolbarPlayerInfoItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSToolbarPlayerInfoItemIdentifier];
  [toolbarPlayerInfoItem setLabel:NSLocalizedString(@"Player Info", nil)];
  toolbarPlayerInfoItem.image = [NSImage imageNamed:NSImageNameUser];
  toolbarPlayerInfoItem.target = self;
  toolbarPlayerInfoItem.action = @selector(prefPane:);

  toolbarKeyConfigItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSToolbarKeyConfigItemIdentifier];
  [toolbarKeyConfigItem setLabel:NSLocalizedString(@"Key Config", nil)];
  toolbarKeyConfigItem.image = [NSImage imageNamed:GSKeyConfigImage];
  toolbarKeyConfigItem.target = self;
  toolbarKeyConfigItem.action = @selector(prefPane:);
  [toolbarKeyConfigItem setEnabled:YES];

  // init the preferences toolbar
  prefToolbar = [[NSToolbar alloc] initWithIdentifier:GSPreferencesToolbar];
  prefToolbar.delegate = self;
  prefToolbar.selectedItemIdentifier = GSToolbarPlayerInfoItemIdentifier;
  preferencesWindow.toolbar = prefToolbar;
  if (@available(macOS 11.0, *)) {
    preferencesWindow.toolbarStyle = NSWindowToolbarStylePreference;
  }

  // init bolo toolbar items
  builderToolItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSBoloToolItemIdentifier];
  [builderToolItem setLabel:NSLocalizedString(@"Builder Tool", nil)];
  builderToolItem.view = builderToolView;
  builderToolItem.minSize = builderToolView.frame.size;

  tankCenterItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSTankCenterItemIdentifier];
  [tankCenterItem setLabel:NSLocalizedString(@"Tank Center", nil)];
  tankCenterItem.image = [NSImage imageNamed:GSTankCenterImage];
  tankCenterItem.target = self;
  tankCenterItem.action = @selector(tankCenter:);

  pillCenterItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSPillCenterItemIdentifier];
  [pillCenterItem setLabel:NSLocalizedString(@"Pill Center", nil)];
  pillCenterItem.image = [NSImage imageNamed:GSPillCenterImage];
  pillCenterItem.target = self;
  pillCenterItem.action = @selector(pillCenter:);

  zoomInItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSZoomInItemIdentifier];
  [zoomInItem setLabel:NSLocalizedString(@"Zoom In", nil)];
  zoomInItem.image = [NSImage imageNamed:GSZoomInImage];
  zoomInItem.target = self;
  zoomInItem.action = @selector(zoomIn:);

  zoomOutItem = [[NSToolbarItem alloc] initWithItemIdentifier:GSZoomOutItemIdentifier];
  [zoomOutItem setLabel:NSLocalizedString(@"Zoom Out", nil)];
  zoomOutItem.image = [NSImage imageNamed:GSZoomOutImage];
  zoomOutItem.target = self;
  zoomOutItem.action = @selector(zoomOut:);

  // init the builder toolbar
  boloToolbar = [[NSToolbar alloc] initWithIdentifier:GSBoloToolbar];
  boloToolbar.delegate = self;
  [boloToolbar setAllowsUserCustomization:YES];
  boloWindow.toolbar = boloToolbar;
  if (@available(macOS 11.0, *)) {
    boloWindow.toolbarStyle = NSWindowToolbarStyleExpanded;
  }

  // init status bars
  playerShellsStatusBar.type = GSStatusBarVertical;
  playerMinesStatusBar.type = GSStatusBarVertical;
  playerArmourStatusBar.type = GSStatusBarVertical;
  playerTreesStatusBar.type = GSStatusBarVertical;
  baseShellsStatusBar.type = GSStatusBarHorizontal;
  baseMinesStatusBar.type = GSStatusBarHorizontal;
  baseArmourStatusBar.type = GSStatusBarHorizontal;

  // we don't need no stink'n windows menu
  [newGameWindow setExcludedFromWindowsMenu:YES];
  [boloWindow setExcludedFromWindowsMenu:YES];
  [statusPanel setExcludedFromWindowsMenu:YES];
  [allegiancePanel setExcludedFromWindowsMenu:YES];
  [messagesPanel setExcludedFromWindowsMenu:YES];
  [preferencesWindow setExcludedFromWindowsMenu:YES];

  // keep panels visible
  [statusPanel setHidesOnDeactivate:NO];
  [allegiancePanel setHidesOnDeactivate:NO];
  [messagesPanel setHidesOnDeactivate:NO];

  /* Fix allegiancePanel column widths */
  playerInfoTableView.tableColumns[0].width = MAX(playerInfoTableView.tableColumns[0].minWidth, allegiancePanel.frame.size.width - playerInfoTableView.tableColumns[1].width);

  // init the host pane
  [self setHostMap:[defaults URLForKey:GSHostMap]];
  [self setHostUPnP:[defaults boolForKey:GSHostUPnP]];
  if([defaults boolForKey:@"GSHostPortNumberRandom"])
    [self setHostPort:(random() % 40000) + 2000];
  else
    [self setHostPort:(int)[defaults integerForKey:GSHostPort]];
  [self setHasHostPassword:[defaults boolForKey:GSHostUsePassword]];
  [self setHostPassword:[defaults stringForKey:GSHostPassword]];
  [self setHasHostTimeLimit:[defaults boolForKey:GSHostUseTimeLimit]];
  [self setHostTimeLimit:[defaults stringForKey:GSHostTimeLimit]];
  [self setHostHiddenMines:[defaults boolForKey:GSHostHiddenMines]];
  [self setHostTracker:[defaults boolForKey:GSHostTracker]];
  [self setHostGameType:(int)[defaults integerForKey:GSHostGameType]];
  
  // load default map
  defaultHostMapURL = [[NSBundle mainBundle] URLForResource:@"Everard Island" withExtension:@"bmap"];
  if (!hostMapURL && defaultHostMapURL) {
    [self setHostMap:defaultHostMapURL];
    hostMapResetButton.enabled = false;
  } else {
    hostMapResetButton.enabled = true;
  }

  // init host domination pane
  [self setHostDominationType:(int)[defaults integerForKey:GSHostDominationType]];
  [self setHostDominationBaseControl:[defaults stringForKey:GSHostDominationBaseControl]];

  // init the join pane
  [self setJoinAddress:[defaults stringForKey:GSJoinAddress]];
  [self setJoinPort:(int)[defaults integerForKey:GSJoinPort]];
  [self setJoinPasswordEnabled:[defaults boolForKey:GSJoinHasPassword]];
  [self setJoinPassword:[defaults stringForKey:GSJoinPassword]];

  // init tracker string
  [self setTracker:[defaults stringForKey:GSTracker]];

  // init the pref panes
  [self setPrefPaneIdentifier:[defaults stringForKey:GSPrefPaneIdentifier]];
  [self setPlayerName:[defaults stringForKey:GSPlayerNameString]];
  [self setAutoSlowdown:[defaults boolForKey:GSAutoSlowdown]];
  [self revertKeyConfig:self];

  // init the show variables
  [self setShowStatus:[defaults boolForKey:GSShowStatus]];
  [self setShowAllegiance:[defaults boolForKey:GSShowAllegiance]];
  [self setShowMessages:[defaults boolForKey:GSShowMessages]];

  // init bolo window
  [self setBuilderTool:(int)[defaults integerForKey:GSBuilderTool]];

  // init allegiance panel
  playerInfoArray = [[NSMutableArray alloc] init];

  // init messages panel
  [self setMessageTarget:(int)[defaults integerForKey:GSMessageTarget]];

  // init the key config
  [self setKeyConfigDict:[defaults dictionaryForKey:GSKeyConfigDict]];

  // schedule a timer
  [NSTimer scheduledTimerWithTimeInterval:0.0625 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];

  // init sound
  [self setMute:[defaults boolForKey:GSMute]];

  // allocate sounds
  NSDataAsset *soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/bubbles"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"bubbles"];
  bubblessounds = [[NSMutableArray alloc] init];
  [bubblessounds addObject:sound];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/build"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"build"];
  buildsounds = [[NSMutableArray alloc] init];
  [buildsounds addObject:sound];
  [buildsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/builderdeath"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"builderdeath"];
  builderdeathsounds = [[NSMutableArray alloc] init];
  [builderdeathsounds addObject:sound];
  [builderdeathsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/explosion"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"explosion"];
  explosionsounds = [[NSMutableArray alloc] init];
  [explosionsounds addObject:sound];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];
  [explosionsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/fbuild"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"fbuild"];
  farbuildsounds = [[NSMutableArray alloc] init];
  [farbuildsounds addObject:sound];
  [farbuildsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/fbuilderdeath"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"fbuilderdeath"];
  farbuilderdeathsounds = [[NSMutableArray alloc] init];
  [farbuilderdeathsounds addObject:sound];
  [farbuilderdeathsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/fexplosion"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"fexplosion"];
  farexplosionsounds = [[NSMutableArray alloc] init];
  [farexplosionsounds addObject:sound];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];
  [farexplosionsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/fhittank"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"fhittank"];
  farhittanksounds = [[NSMutableArray alloc] init];
  [farhittanksounds addObject:sound];
  [farhittanksounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/fhitterrain"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"fhitterrain"];
  farhitterrainsounds = [[NSMutableArray alloc] init];
  [farhitterrainsounds addObject:sound];
  [farhitterrainsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/fhittree"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"fhittree"];
  farhittreesounds = [[NSMutableArray alloc] init];
  [farhittreesounds addObject:sound];
  [farhittreesounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/fshot"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"fshot"];
  farshotsounds = [[NSMutableArray alloc] init];
  [farshotsounds addObject:sound];
  [farshotsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/fsink"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"fsink"];
  farsinksounds = [[NSMutableArray alloc] init];
  [farsinksounds addObject:sound];
  [farsinksounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/fsuperboom"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"fsuperboom"];
  farsuperboomsounds = [[NSMutableArray alloc] init];
  [farsuperboomsounds addObject:sound];
  [farsuperboomsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/ftree"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"ftree"];
  fartreesounds = [[NSMutableArray alloc] init];
  [fartreesounds addObject:sound];
  [fartreesounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/hittank"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"hittank"];
  hittanksounds = [[NSMutableArray alloc] init];
  [hittanksounds addObject:sound];
  [hittanksounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/hitterrain"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"hitterrain"];
  hitterrainsounds = [[NSMutableArray alloc] init];
  [hitterrainsounds addObject:sound];
  [hitterrainsounds addObject:[sound copy]];
  [hitterrainsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/hittree"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"hittree"];
  hittreesounds = [[NSMutableArray alloc] init];
  [hittreesounds addObject:sound];
  [hittreesounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/mine"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"mine"];
  minesounds = [[NSMutableArray alloc] init];
  [minesounds addObject:sound];
  [minesounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/msgreceived"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"msgreceived"];
  msgreceivedsounds = [[NSMutableArray alloc] init];
  [msgreceivedsounds addObject:sound];
  [msgreceivedsounds addObject:[sound copy]];
  [msgreceivedsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/pillshot"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"pillshot"];
  pillshotsounds = [[NSMutableArray alloc] init];
  [pillshotsounds addObject:sound];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];
  [pillshotsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/sink"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"sink"];
  sinksounds = [[NSMutableArray alloc] init];
  [sinksounds addObject:sound];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/superboom"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"superboom"];
  superboomsounds = [[NSMutableArray alloc] init];
  [superboomsounds addObject:sound];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/tankshot"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"tankshot"];
  tankshotsounds = [[NSMutableArray alloc] init];
  [tankshotsounds addObject:sound];
  [tankshotsounds addObject:[sound copy]];
  [tankshotsounds addObject:[sound copy]];
  [tankshotsounds addObject:[sound copy]];
  [tankshotsounds addObject:[sound copy]];

  soundAsset = [[NSDataAsset alloc] initWithName:@"Sounds/tree"];
  sound = [[NSSound alloc] initWithData:soundAsset.data];
  [sound setName:@"tree"];
  treesounds = [[NSMutableArray alloc] init];
  [treesounds addObject:sound];
  [treesounds addObject:[sound copy]];
  [treesounds addObject:[sound copy]];

  speechSynthesizers = [[NSMutableArray alloc] init];
  [speechSynthesizers addObject:[[NSSpeechSynthesizer alloc] init]];
  [speechSynthesizers addObject:[[NSSpeechSynthesizer alloc] init]];

  zoomLevel = DEFAULT_ZOOM;

  // bug in interface builder prevents this outlet from working
  joinProgressStatusTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(76, 60, 193, 17)];
  [joinProgressStatusTextField setBordered:NO];
  [joinProgressStatusTextField setEditable:NO];
  [joinProgressStatusTextField setDrawsBackground:NO];
  [joinProgressWindow.contentView addSubview:joinProgressStatusTextField];

  joinProgressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(18, 18, 172, 20)];
  [joinProgressWindow.contentView addSubview:joinProgressIndicator];

  // setup double clicking in tracker
  joinTrackerTableView.target = self;
  joinTrackerTableView.doubleAction = @selector(joinOK:);

  // TCMPortMapper
  portMapper = [TCMPortMapper sharedInstance];
  [portMapper setUserID:[NSString stringWithFormat:@"%d", getpid()]];
 
  // set up robots menu
  [self setupRobotsMenu];
  
  // Register for Bonjour Services
  __weak typeof(self) weakSelf = self;

  broadcaster = [[XBoloBonjour alloc] init];
  broadcaster.gameInfoBlock = ^(XBoloBonjourGameInfo *gameInfo) {
    GSXBoloController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    NSDictionary *toSet =
    @{GSHostPlayerColumn: gameInfo.playerName,
      GSMapNameColumn: gameInfo.mapName,
      GSPlayersColumn: gameInfo.playerCount,
      GSPasswordColumn: gameInfo.passReq,
      GSAllowJoinColumn: gameInfo.canJoin,
      GSPausedColumn: gameInfo.paused,
      GSHostnameColumn: gameInfo.hostName,
      GSPortColumn: gameInfo.port,
      GSSourceColumn: @(GSServerSourceBonjour),
      GSNetServiceKey: gameInfo.service};

    NSMutableArray *newTrackArr = strongSelf->joinTrackerArray;
    if (!newTrackArr) {
      newTrackArr = [[NSMutableArray alloc] init];
    }

    NSUInteger idx = [newTrackArr indexOfObjectPassingTest:^BOOL(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      return obj[GSNetServiceKey] == gameInfo.service;
    }];

    if (idx != NSNotFound) {
      [newTrackArr replaceObjectAtIndex:idx withObject:toSet];
    } else {
      [newTrackArr addObject:toSet];
    }
    [strongSelf setJoinTrackerArray:newTrackArr];
  };
  broadcaster.gameInfoRemovedBlock = ^(NSNetService * _Nonnull service) {
    GSXBoloController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    NSDictionary *toRemove;
    for (NSDictionary *theDict in strongSelf->joinTrackerArray) {
      if ([theDict[GSNetServiceKey] isEqual:service]) {
        toRemove = theDict;
        break;
      }
    }

    [strongSelf->joinTrackerArray removeObject:toRemove];
    [strongSelf setJoinTrackerArray:strongSelf->joinTrackerArray];
  };

  if (![defaults boolForKey:GSDisableBonjour]) {
    [broadcaster startListening];
  }
  
  _broadcastBonjour = ![defaults boolForKey:GSDisableBonjour];
}

// accessor methods

@synthesize hostMap=hostMapURL;
- (void)setHostMap:(NSURL *)aURL {
  if (!aURL) {
    hostMapURL = nil;
    hostMapField.stringValue = @"";
  } else {
    hostMapURL = [aURL copy];
    NSString *hostMapName = nil;
    if ([aURL getResourceValue:&hostMapName forKey:NSURLLocalizedNameKey error:NULL]) {
      hostMapField.stringValue = hostMapName.stringByDeletingPathExtension;
    } else {
      hostMapField.stringValue = aURL.lastPathComponent.stringByDeletingPathExtension;
    }
    [[NSUserDefaults standardUserDefaults] setURL:aURL forKey:GSHostMap];
  }
  hostMapResetButton.enabled = hostMapURL != defaultHostMapURL;
}

@synthesize hostUPnP=hostUPnPBool;
- (void)setHostUPnP:(BOOL)aBool {
  hostUPnPBool = aBool;
  hostUPnPSwitch.state = aBool ? NSOnState : NSOffState;
  hostPortField.enabled = !aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostUPnP];
}

- (void)setHostPort:(unsigned short)aNumber {
  hostPortNumber = aNumber;
  hostPortField.intValue = aNumber;
  [[NSUserDefaults standardUserDefaults] setInteger:aNumber forKey:GSHostPort];
}

@synthesize hasHostPassword=hostPasswordBool;
- (void)setHasHostPassword:(BOOL)aBool {
  hostPasswordBool = aBool;
  hostPasswordSwitch.state = aBool ? NSOnState : NSOffState;
  hostPasswordField.enabled = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostUsePassword];
}

@synthesize hostPassword=hostPasswordString;
- (void)setHostPassword:(NSString *)aString {
  hostPasswordString = [aString copy];
  hostPasswordField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSHostPassword];
}

@synthesize hasHostTimeLimit=hostTimeLimitBool;
- (void)setHasHostTimeLimit:(BOOL)aBool {
  hostTimeLimitBool = aBool;
  hostTimeLimitSwitch.state = aBool ? NSOnState : NSOffState;
  hostTimeLimitSlider.enabled = aBool;
  hostTimeLimitField.enabled = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostUseTimeLimit];
}

@synthesize hostTimeLimit=hostTimeLimitString;
- (void)setHostTimeLimit:(NSString *)aString {
  NSScanner *scanner;
  int hours, minutes, seconds;

  scanner = [NSScanner scannerWithString:aString];
  scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@":"];
  [scanner scanInt:&hours];
  [scanner scanInt:&minutes];
  [scanner scanInt:&seconds];
  hostTimeLimitString = [aString copy];
  hostTimeLimitSlider.intValue = hours*3600 + minutes*60 + seconds;
  hostTimeLimitField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSHostTimeLimit];
}

@synthesize hostHiddenMines=hostHiddenMinesBool;
- (void)setHostHiddenMines:(BOOL)aBool {
  hostHiddenMinesBool = aBool;
  hostHiddenMinesSwitch.state = aBool ? NSOnState : NSOffState;

  if (aBool) {
    hostHiddenMinesTextField.stringValue = NSLocalizedString(@"Mines May Be Hidden", @"Mines May Be Hidden");
  }
  else {
    hostHiddenMinesTextField.stringValue = NSLocalizedString(@"Mines Will Always Be Visible", @"Mines Will Always Be Visible");
  }

  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostHiddenMines];
}

@synthesize hostTracker=hostTrackerBool;
- (void)setHostTracker:(BOOL)aBool {
  hostTrackerBool = aBool;
  hostTrackerSwitch.state = hostTrackerBool ? NSOnState : NSOffState;
  hostTrackerField.enabled = hostTrackerBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSHostTracker];
}

@synthesize hostGameType=hostGameTypeNumber;
- (void)setHostGameType:(int)aNumber {
  hostGameTypeNumber = aNumber;
  [hostGameTypeMenu selectItemAtIndex:aNumber];
  [hostGameTypeTab selectTabViewItemAtIndex:aNumber];
  [[NSUserDefaults standardUserDefaults] setInteger:aNumber forKey:GSHostGameType];
}

@synthesize hostDominationType=hostDominationTypeNumber;
- (void)setHostDominationType:(int)aNumber {
  hostDominationTypeNumber = aNumber;
  [hostDominationTypeMatrix selectCellWithTag:aNumber];
  [[NSUserDefaults standardUserDefaults] setInteger:aNumber forKey:GSHostDominationType];
}

@synthesize hostDominationBaseControl=hostDominationBaseControlString;
- (void)setHostDominationBaseControl:(NSString *)aString {
  int hours, minutes, seconds;
  NSScanner *scanner = [NSScanner scannerWithString:aString];
  scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@":"];
  [scanner scanInt:&hours];
  [scanner scanInt:&minutes];
  [scanner scanInt:&seconds];
  hostDominationBaseControlString = [aString copy];
  hostDominationBaseControlSlider.intValue = hours*3600 + minutes*60 + seconds;
  hostDominationBaseControlField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSHostDominationBaseControl];
}

- (void)setJoinAddress:(NSString *)newJoinAddressString {
  joinAddressString = [newJoinAddressString copy];
  joinAddressField.stringValue = newJoinAddressString;
  [[NSUserDefaults standardUserDefaults] setObject:newJoinAddressString forKey:GSJoinAddress];
}

- (void)setJoinPort:(unsigned short)aNumber {
  joinPortNumber = aNumber;
  joinPortField.intValue = aNumber;
  [[NSUserDefaults standardUserDefaults] setInteger:aNumber forKey:GSJoinPort];
}

- (void)setJoinPasswordEnabled:(BOOL)aBool {
  joinPasswordBool = aBool;
  joinPasswordSwitch.state = aBool ? NSOnState : NSOffState;
  joinPasswordField.enabled = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSJoinHasPassword];
}

- (void)setJoinPassword:(NSString *)aString {
  joinPasswordString = [aString copy];
  joinPasswordField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSJoinPassword];
}

- (void)setJoinTrackerArray:(NSArray *)aArray {
  joinTrackerArray = [aArray mutableCopy];
  [joinTrackerArray sortUsingDescriptors:joinTrackerTableView.sortDescriptors];
  [joinTrackerTableView reloadData];
}

- (void)setTracker:(NSString *)aString {
  trackerString = [aString copy];
  hostTrackerField.stringValue = aString;
  joinTrackerField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSTracker];
}

- (void)setPrefPaneIdentifier:(NSString *)aString {
  prefToolbar.selectedItemIdentifier = aString;
  [prefTab selectTabViewItemWithIdentifier:aString];
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSPrefPaneIdentifier];
}

- (NSString*)prefPaneIdentifier
{
  return prefToolbar.selectedItemIdentifier;
}

- (void)setPlayerName:(NSString *)aString {
  playerNameString = [aString copy];
  prefPlayerNameField.stringValue = aString;
  [[NSUserDefaults standardUserDefaults] setObject:aString forKey:GSPlayerNameString];
}

- (void)setKeyConfigDict:(NSDictionary *)aDict {
  keyConfigDict = [aDict copy];
  [[NSUserDefaults standardUserDefaults] setObject:aDict forKey:GSKeyConfigDict];
}

- (void)setAutoSlowdown:(BOOL)aBool {
TRY
  autoSlowdownBool = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSAutoSlowdown];

  if (keyevent(BRAKEMASK, aBool) == -1) LOGFAIL(errno)

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

@synthesize showStatus = showStatusBool;
- (void)setShowStatusBool:(BOOL)aBool {
  showStatusBool = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSShowStatus];
}

@synthesize showAllegiance=showAllegianceBool;
- (void)setShowAllegianceBool:(BOOL)aBool {
  showAllegianceBool = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSShowAllegiance];
}

@synthesize showMessages=showMessagesBool;
- (void)setShowMessagesBool:(BOOL)aBool {
  showMessagesBool = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSShowMessages];
}

@synthesize builderTool=builderToolInt;
- (void)setBuilderTool:(int)anInt {
  builderToolInt = anInt;
  [builderToolMatrix selectCellWithTag:anInt];
  [[NSUserDefaults standardUserDefaults] setInteger:anInt forKey:GSBuilderTool];
}

@synthesize messageTarget=messageTargetInt;

- (void)setMessageTarget:(int)anInt {
  messageTargetInt = anInt;
  [messageTargetMatrix selectCellWithTag:anInt];
  [[NSUserDefaults standardUserDefaults] setInteger:anInt forKey:GSMessageTarget];
}

- (void)setMute:(BOOL)aBool {
  muteBool = aBool;
  muteGlobal = aBool;
  [[NSUserDefaults standardUserDefaults] setBool:aBool forKey:GSMute];
}

/** Return the hostname part of the trackerString */
- (NSString *)trackerHostName {
  NSString *string = [trackerString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSRange r = [string rangeOfString:@":"];
  if (r.location != NSNotFound) {
    return [string substringToIndex:r.location];
  }

  r = [string rangeOfString:@" "];
  if (r.location != NSNotFound) {
    return [string substringToIndex:r.location];
  }

  return string;
}

/** Return the port part of the trackerString, or 0 */
- (in_port_t)trackerPort {
  NSString *string = [trackerString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSRange r = [string rangeOfString:@":"];
  if (r.location != NSNotFound) {
    return [[string substringFromIndex:r.location + 1] intValue];
  }

  r = [string rangeOfString:@" "];
  if (r.location != NSNotFound) {
    return [[string substringFromIndex:r.location + 1] intValue];
  }

  return 0;
}

// IBAction methods

- (IBAction)closeGame:(id)sender {
  [boloWindow orderOut:self];
  [statusPanel orderOut:self];
  [allegiancePanel orderOut:self];
  [messagesPanel orderOut:self];

  if (hostUPnPBool) {
    /* remove port mapping */
    for (TCMPortMapping *portMapping in [portMapper portMappings]) {
      [portMapper removePortMapping:portMapping];
    }
    
    [portMapper start];
  }

  stopclient();

  if (server.setup) {
    stopserver();
    [broadcaster stopPublishing];
  }

  if (!broadcaster.listening) {
    [broadcaster startListening];
  }

  [self newGame:self];
}

- (IBAction)hostChoose:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = @[NSFileTypeForHFSTypeCode('BMAP'), @"map", @"com.gengasw.xbolo.map"];
  if (hostMapURL != nil) {
    panel.directoryURL = hostMapURL.URLByDeletingLastPathComponent;
  }
  
  [panel beginSheetModalForWindow:newGameWindow completionHandler:^(NSInteger returnCode) {
    if (returnCode == NSModalResponseOK) {
      [self setHostMap:panel.URLs[0]];
    }
  }];
}

- (IBAction)hostResetMap:(id)sender {
  [self setHostMap:defaultHostMapURL];
}

- (IBAction)hostUPnPSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHostUPnP:aBool];
  if (!aBool) {
    [hostPortField selectText:self];
  }
}

- (IBAction)hostPort:(id)sender {
  [self setHostPort:[sender intValue]];
}

- (IBAction)hostPasswordSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHasHostPassword:aBool];
  if (aBool) {
    [hostPasswordField selectText:self];
  }
}

- (IBAction)hostPassword:(id)sender {
  [self setHostPassword:[sender stringValue]];
}

- (IBAction)hostTimeLimitSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHasHostTimeLimit:aBool];
  if (aBool) {
    [hostTimeLimitField selectText:self];
  }
}

- (IBAction)hostTimeLimit:(id)sender {
  NSString *aString;
  if ([sender isMemberOfClass:[NSTextField class]]) {
    aString = [sender stringValue];
  }
  else {
    int hours, minutes, seconds;
    int time;
    time = [sender intValue];
    hours = time/3600;
    minutes = (time%3600)/60;
    seconds = (time%3600)%60;
    aString =
      [NSString stringWithFormat:@"%@:%@:%@",
        (hours   >= 10 ? [NSString stringWithFormat:@"%d", hours  ] : [NSString stringWithFormat:@"0%d", hours  ]),
        (minutes >= 10 ? [NSString stringWithFormat:@"%d", minutes] : [NSString stringWithFormat:@"0%d", minutes]),
        (seconds >= 10 ? [NSString stringWithFormat:@"%d", seconds] : [NSString stringWithFormat:@"0%d", seconds])];
  }
  [self setHostTimeLimit:aString];
  [hostTimeLimitField selectText:self];
}

- (IBAction)hostHiddenMinesSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHostHiddenMines:aBool];
}

- (IBAction)hostTrackerSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setHostTracker:aBool];
  if (aBool) {
    [hostTrackerField selectText:self];
  }
}

- (IBAction)hostGameType:(id)sender {
  [self setHostGameType:(int)[sender indexOfSelectedItem]];
}

- (IBAction)hostDominationType:(id)sender {
  [self setHostDominationType:(int)[hostDominationTypeMatrix.selectedCell tag]];
}

- (IBAction)hostDominationBaseControl:(id)sender {
  NSString *aString;
  if ([sender isMemberOfClass:[NSTextField class]]) {
    aString = [sender stringValue];
  }
  else {
    int hours, minutes, seconds;
    int time;
    time = [sender intValue];
    hours = time/3600;
    minutes = (time%3600)/60;
    seconds = (time%3600)%60;
    aString =
      [NSString stringWithFormat:@"%@:%@:%@",
        (hours   >= 10 ? [NSString stringWithFormat:@"%d", hours  ] : [NSString stringWithFormat:@"0%d", hours  ]),
        (minutes >= 10 ? [NSString stringWithFormat:@"%d", minutes] : [NSString stringWithFormat:@"0%d", minutes]),
        (seconds >= 10 ? [NSString stringWithFormat:@"%d", seconds] : [NSString stringWithFormat:@"0%d", seconds])];
  }

  [self setHostDominationBaseControl:aString];
  [hostDominationBaseControlField selectText:self];
}

- (void)portMapperDidFinishWork:(NSNotification *)aNotification {
TRY
  for (TCMPortMapping *mapping in [portMapper portMappings]) {
    if ([mapping localPort] == getservertcpport()) {
      if ([mapping mappingStatus] == TCMPortMappingStatusMapped && [mapping transportProtocol] == TCMPortMappingTransportProtocolBoth) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMPortMapperDidFinishWorkNotification object:portMapper];
        
        if (hostTrackerBool) {
          startserverthreadwithtracker([self trackerHostName].UTF8String, [self trackerPort], [mapping externalPort], playerNameString.UTF8String, hostMapURL.lastPathComponent.UTF8String, registercallback);
        }
        else {
          if (hostTrackerBool) {  /* not using UPnP but registering with tracker */
            if (startserverthreadwithtracker([self trackerHostName].UTF8String, [self trackerPort], getservertcpport(), playerNameString.UTF8String, hostMapURL.lastPathComponent.UTF8String, registercallback)) LOGFAIL(errno)
          }
          else {
            if (startserverthread()) LOGFAIL(errno)
            if (startclient("localhost", getservertcpport(), playerNameString.UTF8String, hostPasswordBool ? hostPasswordString.UTF8String : NULL)) LOGFAIL(errno)
            [boloView reset];
          }

          break;
        }
      }
      else {
        NSSet<TCMPortMapping*> *mappings;

        [joinProgressWindow orderOut:self];
        [joinProgressIndicator stopAnimation:self];
        [newGameWindow endSheet:joinProgressWindow];

        [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMPortMapperDidFinishWorkNotification object:portMapper];

        mappings = [[portMapper portMappings] copy];

        for (TCMPortMapping *portMapping in mappings) {
          [portMapper removePortMapping:portMapping];
        }

        [portMapper start];

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = NSLocalizedString(@"UPnP Failed", @"UPnP Failed");
        alert.informativeText = NSLocalizedString(@"UPnP was unable to map to a port.  Please check your router settings.", @"UPnP Failed reason");
        [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
          //do nothing
        }];

        if (stopserver()) LOGFAIL(errno)
      }
    }
  }

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

- (IBAction)hostOK:(id)sender {
  //Always stop listening for Bonjour methods.
  [broadcaster stopListening];
  
  NSData *mapData = nil;
  [newGameWindow makeFirstResponder:nil];

TRY
  if (hostMapURL == nil) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"No map chosen.", @"No map chosen.");
    alert.informativeText = NSLocalizedString(@"Please try another map.", @"Please try another map.");
    [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
      //do nothing
    }];
    [broadcaster startListening];
  }
  else if (mapData == nil && (mapData = [NSData dataWithContentsOfURL:hostMapURL]) == nil) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Error occured when openning map.", @"Error occured when openning map.");
    alert.informativeText = NSLocalizedString(@"Please try another map.", @"Please try another map.");
    [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
      //do nothing
    }];
    [self setHostMap:nil];
    [broadcaster startListening];
  }
  else {
    NSScanner *scanner;
    int hours, minutes, seconds, timelimit;
    struct Domination domination;
    int paused;

    scanner = [NSScanner scannerWithString:hostTimeLimitString];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@":"];
    [scanner scanInt:&hours];
    [scanner scanInt:&minutes];
    [scanner scanInt:&seconds];
    timelimit = hours*3600 + minutes*60 + seconds;

    domination.type = hostDominationTypeNumber;
    scanner = [NSScanner scannerWithString:hostDominationBaseControlString];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@":"];
    [scanner scanInt:&hours];
    [scanner scanInt:&minutes];
    [scanner scanInt:&seconds];
    domination.basecontrol = hours*3600 + minutes*60 + seconds;

    if([[NSUserDefaults standardUserDefaults] boolForKey:@"GSStartGameImmediately"]) {
      paused = 0;
    }
    else {
      paused = 1;
    }

    joinProgressStatusTextField.stringValue = NSLocalizedString(@"Starting...", @"Starting...");
    [joinProgressIndicator setIndeterminate:YES];
    joinProgressIndicator.doubleValue = 0.0;
    [joinProgressIndicator startAnimation:self];
    [newGameWindow beginSheet:joinProgressWindow completionHandler:^(NSModalResponse returnCode) {
      
    }];

    if (setupserver(paused, mapData.bytes, mapData.length, hostUPnPBool ? 0 : hostPortNumber, hostPasswordBool ? hostPasswordString.UTF8String : NULL, hostTimeLimitBool ? timelimit : 0, hostHiddenMinesBool, 0, hostGameTypeNumber, &domination)) LOGFAIL(errno)

    /* if using UPnP */
    if (hostUPnPBool) {
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidFinishWork:) name:TCMPortMapperDidFinishWorkNotification object:portMapper];
      [portMapper addPortMapping:[TCMPortMapping portMappingWithLocalPort:getservertcpport() desiredExternalPort:getservertcpport() transportProtocol:TCMPortMappingTransportProtocolBoth userInfo:nil]];
      [portMapper start];

      joinProgressStatusTextField.stringValue = @"UPnP Mapping Port...";
    }
    else if (hostTrackerBool) {  /* not using UPnP but registering with tracker */
      if (startserverthreadwithtracker([self trackerHostName].UTF8String, [self trackerPort], getservertcpport(), playerNameString.UTF8String, hostMapURL.lastPathComponent.UTF8String, registercallback)) LOGFAIL(errno)
    }
    else {  /* not using UPnP and not registering with tracker */
      if (startserverthread()) LOGFAIL(errno)
      if (startclient("localhost", getservertcpport(), playerNameString.UTF8String, hostPasswordBool ? hostPasswordString.UTF8String : NULL)) LOGFAIL(errno)
      [boloView reset];
    }

    NSString *bonjourName = [NSString stringWithFormat:@"%@ (%@)", [NSHost currentHost].localizedName, playerNameString];
    broadcaster.serviceName = bonjourName;
    broadcaster.mapName = hostMapURL.lastPathComponent.stringByDeletingPathExtension;

    if (_broadcastBonjour) { /* always check if we're broadcasting via Bonjour */
      [broadcaster startPublishing];
    }
  }

CLEANUP
  NSAlert *alert;
  switch (ERROR) {
  case 0:
    break;

  case ECORFILE:
    [joinProgressWindow orderOut:self];
    [joinProgressIndicator stopAnimation:self];
    [newGameWindow endSheet:joinProgressWindow];
    alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Unable to Open Map File", @"Unable to Open Map File");
    alert.informativeText = NSLocalizedString(@"Please choose another map.", @"Please choose another map.");
    [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
      //do nothing
    }];
    [broadcaster startListening];
    CLEARERRLOG
    break;

  case EINCMPAT:
    [joinProgressWindow orderOut:self];
    [joinProgressIndicator stopAnimation:self];
    [newGameWindow endSheet:joinProgressWindow];
    alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Incomaptile Map Version", @"Incompatible Map Version");
    alert.informativeText = NSLocalizedString(@"Please choose another map.", @"Please choose another map.");
    [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
      //do nothing
    }];
    [broadcaster startListening];
    CLEARERRLOG
    break;

  case EADDRINUSE:
    [joinProgressWindow orderOut:self];
    [joinProgressIndicator stopAnimation:self];
    [newGameWindow endSheet:joinProgressWindow];
    alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Port Unavailable", @"Port Unavailable");
    alert.informativeText = NSLocalizedString(@"Please choose another port.", @"Please choose another port.");
    [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
      //do nothing
    }];
    [broadcaster startListening];
    CLEARERRLOG
    break;

  default:
    [joinProgressWindow orderOut:self];
    [joinProgressIndicator stopAnimation:self];
    [newGameWindow endSheet:joinProgressWindow];
    alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"Unexpected Error", @"Unexpected Error");
    alert.informativeText = [NSString stringWithFormat:@"Error #%d: %s", ERROR, strerror(ERROR)];
    [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
      //do nothing
    }];
    [broadcaster startListening];
    CLEARERRLOG
    break;
  }
END
}

- (IBAction)joinAddress:(id)sender {
  [self setJoinAddress:[sender stringValue]];
}

- (IBAction)joinPort:(id)sender {
  [self setJoinPort:[sender intValue]];
}

- (IBAction)joinPasswordSwitch:(NSButton*)sender {
  BOOL aBool;
  aBool = sender.state == NSOnState;
  [self setJoinPasswordEnabled:aBool];

  if (aBool) {
    [joinPasswordField selectText:self];
  }
}

- (IBAction)joinPassword:(id)sender {
  self.joinPassword = [sender stringValue];
}

- (IBAction)tracker:(id)sender {
  self.tracker = [sender stringValue];
}

- (IBAction)joinTrackerRefresh:(id)sender {
TRY
  [newGameWindow makeFirstResponder:nil];
  
  [joinTrackerTableView deselectAll:self];
  joinProgressStatusTextField.stringValue = @"";
  [joinProgressIndicator setIndeterminate:YES];
  joinProgressIndicator.doubleValue = 0.0;
  [joinProgressIndicator startAnimation:self];
  [newGameWindow beginSheet:joinProgressWindow completionHandler:^(NSModalResponse returnCode) {
    // do nothing
  }];
  
  // get tracker list from bolo
  if (initlist(&trackerlist)) LOGFAIL(errno)
  if (listtracker([self trackerHostName].UTF8String, [self trackerPort], &trackerlist, getlisttrackerstatus)) LOGFAIL(errno)
  if (broadcaster.listening) {
    // "Have you tried turning it off then on again?"
    [broadcaster stopListening];
    [broadcaster startListening];
  }

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

- (IBAction)joinOK:(id)sender {
TRY
  [newGameWindow makeFirstResponder:nil];

  joinProgressStatusTextField.stringValue = @"";
  [joinProgressIndicator setIndeterminate:YES];
  joinProgressIndicator.doubleValue = 0.0;
  [joinProgressIndicator startAnimation:self];
  [newGameWindow beginSheet:joinProgressWindow completionHandler:^(NSModalResponse returnCode) {
    // do nothing
  }];
  if (startclient(joinAddressString.UTF8String, joinPortNumber, playerNameString.UTF8String, joinPasswordBool ? joinPasswordString.UTF8String : NULL)) LOGFAIL(errno)
  [boloView reset];

  //Always stop listening for Bonjour methods.
  [broadcaster stopListening];

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

- (IBAction)joinCancel:(id)sender {
  NSEnumerator *enumerator;
  TCMPortMapping *portMapping;

TRY
  /* remove notifications from portmapper */
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCMPortMapperDidFinishWorkNotification object:portMapper];

  /* remove all port maps */
  enumerator = [[portMapper portMappings] objectEnumerator];

  while ((portMapping = [enumerator nextObject])) {
    [portMapper removePortMapping:portMapping];
  }

  [portMapper start];

  if (client_running) {
    if (stopclient()) LOGFAIL(errno)
  }

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  /* close modal window */
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];

CLEANUP
  switch (ERROR) {
  case 0:
    return;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
  }
END
}

- (IBAction)boloWindow:(id)sender {
  [boloWindow makeKeyAndOrderFront:self];
}

- (IBAction)statusPanel:(id)sender {
  if (statusPanel.keyWindow) {
    [boloWindow makeKeyAndOrderFront:self];
  }
  else {
    [statusPanel makeKeyAndOrderFront:self];
  }
}

- (IBAction)allegiancePanel:(id)sender {
  if (allegiancePanel.keyWindow) {
    [boloWindow makeKeyAndOrderFront:self];
  }
  else {
    [allegiancePanel makeKeyAndOrderFront:self];
  }
}

- (IBAction)messagesPanel:(id)sender {
  if (messagesPanel.keyWindow) {
    [boloWindow makeKeyAndOrderFront:self];
  }
  else {
    [messagesPanel makeKeyAndOrderFront:self];
  }
}

- (IBAction)newGame:(id)sender {
  [newGameWindow makeKeyAndOrderFront:self];
}

- (IBAction)toggleJoin:(id)sender {
  togglejoingame();
  [broadcaster updatePublishedInfo];
}

- (IBAction)toggleMute:(id)sender {
  [self setMute:!muteBool];
}

- (IBAction)gamePauseResumeMenu:(id)sender {
  pauseresumegame();
  [broadcaster updatePublishedInfo];
}

- (IBAction)kickPlayer:(id)sender {
  kickplayer((int)[sender tag]);
  [broadcaster updatePublishedInfo];
}

- (IBAction)banPlayer:(id)sender {
  banplayer((int)[sender tag]);
  [broadcaster updatePublishedInfo];
}

- (IBAction)unbanPlayer:(id)sender {
  unbanplayer((int)[sender tag]);
  [broadcaster updatePublishedInfo];
}

- (IBAction)scrollUp:(id)sender {
  [boloView scroll:CGPointMake(0, 16)];
}

- (IBAction)scrollDown:(id)sender {
  [boloView scroll:CGPointMake(0, -16)];
}

- (IBAction)scrollLeft:(id)sender {
  [boloView scroll:CGPointMake(-16, 0)];
}

- (IBAction)scrollRight:(id)sender {
  [boloView scroll:CGPointMake(16, 0)];
}

- (IBAction)requestAlliance:(id)sender {
  NSInteger i;
  NSIndexSet *set;
  uint16_t players;
  int gotlock = 0;

TRY
  players = 0;
  set = playerInfoTableView.selectedRowIndexes;

  for (i = 0; (i = [set indexGreaterThanOrEqualToIndex:i]) != NSNotFound; i++) {
    players |= 1 << [playerInfoArray[i][@"Index"] intValue];
  }

  // lock client
  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  if (requestalliance(players)) LOGFAIL(errno)

  // unlock client
  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

CLEANUP
  if (gotlock) {
    unlockclient();
  }

  switch (ERROR) {
  case 0:
    return;

  default:
    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
  }
END
}

- (IBAction)leaveAlliance:(id)sender {
  NSInteger i;
  NSIndexSet *set;
  uint16_t players;
  BOOL gotlock = 0;

TRY
  players = 0;
  set = playerInfoTableView.selectedRowIndexes;

  for (i = 0; (i = [set indexGreaterThanOrEqualToIndex:i]) != NSNotFound; i++) {
    players |= 1 << [playerInfoArray[i][@"Index"] intValue];
  }

  // lock client
  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  if (leavealliance(players)) LOGFAIL(errno)

  // unlock client
  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    if (gotlock) {
      unlockclient();
    }

    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (IBAction)sendMessage:(id)sender {
TRY
  if (sendmessage(messageTextField.stringValue.UTF8String, messageTargetInt)) LOGFAIL(errno)
  [messageTextField selectText:self];

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

- (IBAction)messageTarget:(id)sender {
  id cell;

  if ((cell = [sender selectedCell]) != nil) {
    [self setMessageTarget:(int)[cell tag]];
  }
}

- (IBAction)showPrefs:(id)sender {
  [preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)prefPane:(id)sender {
  [self setPrefPaneIdentifier:[sender itemIdentifier]];
}

- (IBAction)prefPlayerName:(id)sender {
  self.playerName = [sender stringValue];
}

- (IBAction)revertKeyConfig:(id)sender {
  NSDictionary *dict;
  dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:GSKeyConfigDict];
  prefAccelerateField.stringValue = [dict allKeysForObject:GSAccelerate][0];
  prefBrakeField.stringValue = [dict allKeysForObject:GSBrake][0];
  prefTurnLeftField.stringValue = [dict allKeysForObject:GSTurnLeft][0];
  prefTurnRightField.stringValue = [dict allKeysForObject:GSTurnRight][0];
  prefLayMineField.stringValue = [dict allKeysForObject:GSLayMine][0];
  prefShootField.stringValue = [dict allKeysForObject:GSShoot][0];
  prefIncreaseAimField.stringValue = [dict allKeysForObject:GSIncreaseAim][0];
  prefDecreaseAimField.stringValue = [dict allKeysForObject:GSDecreaseAim][0];
  prefUpField.stringValue = [dict allKeysForObject:GSUp][0];
  prefDownField.stringValue = [dict allKeysForObject:GSDown][0];
  prefLeftField.stringValue = [dict allKeysForObject:GSLeft][0];
  prefRightField.stringValue = [dict allKeysForObject:GSRight][0];
  prefTankViewField.stringValue = [dict allKeysForObject:GSTankView][0];
  prefPillViewField.stringValue = [dict allKeysForObject:GSPillView][0];
  prefAutoSlowdownSwitch.state = [[NSUserDefaults standardUserDefaults] boolForKey:GSAutoSlowdown] ? NSOnState : NSOffState;
}

- (IBAction)applyKeyConfig:(id)sender {
  NSMutableDictionary<NSString*,NSString*> *dict;
  dict = [NSMutableDictionary dictionary];
  if
    (
      !(
        setKey(dict, preferencesWindow, prefAccelerateField, GSAccelerate) ||
        setKey(dict, preferencesWindow, prefBrakeField, GSBrake) ||
        setKey(dict, preferencesWindow, prefTurnLeftField, GSTurnLeft) ||
        setKey(dict, preferencesWindow, prefTurnRightField, GSTurnRight) ||
        setKey(dict, preferencesWindow, prefLayMineField, GSLayMine) ||
        setKey(dict, preferencesWindow, prefShootField, GSShoot) ||
        setKey(dict, preferencesWindow, prefIncreaseAimField, GSIncreaseAim) ||
        setKey(dict, preferencesWindow, prefDecreaseAimField, GSDecreaseAim) ||
        setKey(dict, preferencesWindow, prefUpField, GSUp) ||
        setKey(dict, preferencesWindow, prefDownField, GSDown) ||
        setKey(dict, preferencesWindow, prefLeftField, GSLeft) ||
        setKey(dict, preferencesWindow, prefRightField, GSRight) ||
        setKey(dict, preferencesWindow, prefTankViewField, GSTankView) ||
        setKey(dict, preferencesWindow, prefPillViewField, GSPillView)
      )
    )
  {
    [self setKeyConfigDict:dict];
    [self setAutoSlowdown:prefAutoSlowdownSwitch.state == NSOnState];
  }
}

// map interface actions

- (IBAction)zoomIn:(id)sender {
  if (zoomLevel < MAX_ZOOM) {
    zoomLevel++;
    CGFloat zoom = kZoomLevels[zoomLevel];
    [boloView zoomTo:zoom];
  }
}

- (IBAction)zoomOut:(id)sender {
  if (zoomLevel > 0) {
    zoomLevel--;
    CGFloat zoom = kZoomLevels[zoomLevel];
    [boloView zoomTo:zoom];
  }
}

- (IBAction)builderTool:(id)sender {
  id cell;

  if ((cell = [sender selectedCell]) != nil) {
    [self setBuilderTool:(int)[cell tag]];
  }
}

- (IBAction)builderToolMenu:(id)sender {
	[self setBuilderTool:(int)[sender tag]];
}

- (IBAction)tankCenter:(id)sender {
  BOOL gotlock = 0;

TRY
  if (lockclient()) LOGFAIL(errno)
    gotlock = 1;

  [boloView tankCenter];

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

- (IBAction)pillCenter:(id)sender {
  BOOL gotlock = 0;

TRY
  if (lockclient()) LOGFAIL(errno)
    gotlock = 1;

  [boloView nextPillCenter];

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

// key event methods
- (void)keyEvent:(BOOL)event forKey:(unsigned short)keyCode {
  NSString *object;

TRY
  object = keyConfigDict[[NSString stringWithFormat:@"%d", keyCode]];
  if (object != nil) {
    if ([object isEqualToString:GSAccelerate]) {
      if (autoSlowdownBool) {
        if (keyevent(ACCELMASK, event) == -1) LOGFAIL(errno)
        if (keyevent(BRAKEMASK, !event) == -1) LOGFAIL(errno)
      }
      else {
        if (keyevent(ACCELMASK, event) == -1) LOGFAIL(errno)
      }
    }
    else if ([object isEqualToString:GSBrake]) {
      if (!autoSlowdownBool) {
        if (keyevent(BRAKEMASK, event) == -1) LOGFAIL(errno)
      }
    }
    else if ([object isEqualToString:GSTurnLeft]) {
      if (keyevent(TURNLMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSTurnRight]) {
      if (keyevent(TURNRMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSLayMine]) {
      if (keyevent(LMINEMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSShoot]) {
      if (keyevent(SHOOTMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSIncreaseAim]) {
      if (keyevent(INCREMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSDecreaseAim]) {
      if (keyevent(DECREMASK, event) == -1) LOGFAIL(errno)
    }
    else if ([object isEqualToString:GSUp]) {
      if (event) {
        [boloView scroll:CGPointMake(0, 16)];
      } else {
        [boloView scroll:CGPointZero];
      }
    }
    else if ([object isEqualToString:GSDown]) {
      if (event) {
        [boloView scroll:CGPointMake(0, -16)];
      } else {
        [boloView scroll:CGPointZero];
      }
    }
    else if ([object isEqualToString:GSLeft]) {
      if (event) {
        [boloView scroll:CGPointMake(-16, 0)];
      } else {
        [boloView scroll:CGPointZero];
      }
    }
    else if ([object isEqualToString:GSRight]) {
      if (event) {
        [boloView scroll:CGPointMake(16, 0)];
      } else {
        [boloView scroll:CGPointZero];
      }
    }
    else if ([object isEqualToString:GSTankView]) {
      if (event) {
        [self tankCenter:self];
      }
    }
    else if ([object isEqualToString:GSPillView]) {
      if (event) {
        [self pillCenter:self];
      }
    }
  }
  else if (keyCode == 18 && event)
    [self setBuilderTool: 0];
  else if (keyCode == 19 && event)
    [self setBuilderTool: 1];
  else if (keyCode == 20 && event)
    [self setBuilderTool: 2];
  else if (keyCode == 21 && event)
    [self setBuilderTool: 3];
  else if (keyCode == 23 && event)
    [self setBuilderTool: 4];

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

// mouse event method
- (void)mouseEvent:(GSPoint)point {
  int gotlock = 0;

TRY
  if (GSPointInRect(GSMakeRect(0, 0, WIDTH, WIDTH), point)) {
    // lock client
    if (lockclient()) LOGFAIL(errno)
    gotlock = 1;

    buildercommand(builderToolInt, point);

    // unlock client
    if (unlockclient()) LOGFAIL(errno)
    gotlock = 0;
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    if (gotlock) {
      unlockclient();
    }

    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

// validate menu items method

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem {
  SEL action;
  action = menuItem.action;
  if (action == @selector(newGame:)) {
    return !client_running;
  }
  else if (action == @selector(closeGame:)) {
    return client_running;
  }
  else if (action == @selector(boloWindow:)) {
    return client_running;
  }
  else if (action == @selector(statusPanel:)) {
    return client_running;
  }
  else if (action == @selector(allegiancePanel:)) {
    return client_running;
  }
  else if (action == @selector(messagesPanel:)) {
    return client_running;
  }
  else if (action == @selector(hostGameType:)) {
    switch (menuItem.tag) {
    case kDominationGameType:  // Domination
      return YES;

    case kCTFGameType:  // Capture the Flag
      return NO;

    case kKOTHGameType:  // King of the Hill
      return NO;

    case kBallGameType:  // Kill the Man with the Ball
      return NO;

    case kBodyGameType:  // Body Count
      return NO;

    default:
      return NO;
    }
  }
  else if (action == @selector(builderToolMenu:)) {
    menuItem.state = menuItem.tag == builderToolInt ? NSOnState : NSOffState;
    return YES;
  }
  else if (action == @selector(gamePauseResumeMenu:)) {
    lockserver();

    if (server.setup) {
      menuItem.state = server.pause ? NSOnState: NSOffState;
      unlockserver();
      return YES;
    }
    else {
      unlockserver();
      return NO;
    }
  }
  else if (action == @selector(toggleJoin:)) {
    lockserver();

    if (server.setup) {
      menuItem.state = server.allowjoin ? NSOnState: NSOffState;
      unlockserver();
      return YES;
    }
    else {
      unlockserver();
      return NO;
    }
  }
  else if (action == @selector(toggleMute:)) {
    menuItem.state = muteBool;
    return YES;
  }
  else if (action == @selector(kickPlayer:)) {
    lockserver();

    if (server.setup) {
      int player, ret;

      player = (int)menuItem.tag;

      if (server.players[player].cntlsock != -1) {
        menuItem.title = [NSString stringWithFormat:@"%@@%@", [NSString stringWithString:@(server.players[player].name)], [NSString stringWithString:@(inet_ntoa(server.players[player].addr.sin_addr))]];
        lockclient();
        ret = player != client.player;
        unlockclient();
      }
      else {
        ret = NO;
      }

      unlockserver();
      menuItem.hidden = !ret;
      return ret;
    }
    else {
      unlockserver();
      [menuItem setHidden:YES];
      return NO;
    }
    return YES;
  }
  else if (action == @selector(banPlayer:)) {
    lockserver();

    if (server.setup) {
      int player, ret;

      player = (int)menuItem.tag;

      if (server.players[player].cntlsock != -1) {
        menuItem.title = [NSString stringWithFormat:@"%@@%@", [NSString stringWithString:@(server.players[player].name)], [NSString stringWithString:@(inet_ntoa(server.players[player].addr.sin_addr))]];
        lockclient();
        ret = player != client.player;
        unlockclient();
      }
      else {
        ret = NO;
      }

      unlockserver();
      menuItem.hidden = !ret;
      return ret;
    }
    else {
      unlockserver();
      [menuItem setHidden:YES];
      return NO;
    }
  }
  else if (action == @selector(choseRobotMenuItem:)) return [self _validateRobotMenuItem: menuItem];
  else if (action == @selector(hostToggleBonjourBroadcast:)) {
    lockserver();

    if (server.setup) {
      menuItem.state = _broadcastBonjour ? NSOnState: NSOffState;
      unlockserver();
      return YES;
    } else {
      menuItem.state = NSOffState;
      unlockserver();
      return NO;
    }
  }
  else {
      return YES;
  }
}

// NSApplication delegate methods

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
  [statusPanel setFloatingPanel:YES];
  [allegiancePanel setFloatingPanel:YES];
  [messagesPanel setFloatingPanel:YES];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
  [statusPanel setFloatingPanel:NO];
  [allegiancePanel setFloatingPanel:NO];
  [messagesPanel setFloatingPanel:NO];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
  if (!client_running) {
    [newGameWindow makeKeyAndOrderFront:self];
    if([[NSUserDefaults standardUserDefaults] boolForKey: @"GSStartGameImmediately"])
      [self hostOK:nil];
    else
    {
        NSString *tojoin = [[NSUserDefaults standardUserDefaults] objectForKey: @"GSJoinGameImmediately"];
        if(tojoin)
        {
            NSArray *components = [tojoin componentsSeparatedByString: @":"];
            [self setJoinAddress: components[0]];
            [self setJoinPort: [components[1] intValue]];
            [self joinOK: nil];
        }
    }
    return YES;
  }
  else {
    return NO;
  }
}

// host with a map file

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
  if (!client_running) {
    [self setHostMap:[NSURL fileURLWithPath:filename]];
    [newGameTabView selectFirstTabViewItem:self];
    [newGameWindow makeKeyAndOrderFront:self];
    return YES;
  }
  else {
    return NO;
  }
}

// NSMenu delegate methods
- (void)menuNeedsUpdate:(NSMenu *)menu {
  NSInteger i;

  for (i = menu.numberOfItems - 1; i >= 0; i--) {
    [menu removeItemAtIndex:i];
  }

  lockserver();

  if (server.setup) {
    struct ListNode *node;
    int i;
    struct BannedPlayer *bannedplayer;
    NSMenuItem *menuItem;

    i = 0;
    node = nextlist(&server.bannedplayers);

    while (node) {
      bannedplayer = ptrlist(node);
      menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@@%@", [NSString stringWithString:@(bannedplayer->name)], [NSString stringWithString:@(inet_ntoa(bannedplayer->sin_addr))]] action:@selector(unbanPlayer:) keyEquivalent:@""];
      menuItem.target = self;
      menuItem.tag = i;
      [menu addItem:menuItem];
      i++;
      node = nextlist(node);
    }
  }

  unlockserver();
}

// NSToolbar methods

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  if (toolbar == prefToolbar) {
    if ([itemIdentifier isEqual:GSToolbarPlayerInfoItemIdentifier]) {
      return toolbarPlayerInfoItem;
    }
    else if ([itemIdentifier isEqual:GSToolbarKeyConfigItemIdentifier]) {
      return toolbarKeyConfigItem;
    }
  }
  else if (toolbar == boloToolbar) {
    if ([itemIdentifier isEqual:GSBoloToolItemIdentifier]) {
      return builderToolItem;
    }
    else if ([itemIdentifier isEqual:GSTankCenterItemIdentifier]) {
      return tankCenterItem;
    }
    else if ([itemIdentifier isEqual:GSPillCenterItemIdentifier]) {
      return pillCenterItem;
    }
    else if ([itemIdentifier isEqual:GSZoomInItemIdentifier]) {
      return zoomInItem;
    }
    else if ([itemIdentifier isEqual:GSZoomOutItemIdentifier]) {
      return zoomOutItem;
    }
  }
  return nil;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  if (toolbar == prefToolbar) {
    return @[GSToolbarPlayerInfoItemIdentifier, GSToolbarKeyConfigItemIdentifier];
  }
  else if (toolbar == boloToolbar) {
    return @[GSBoloToolItemIdentifier, GSTankCenterItemIdentifier, GSPillCenterItemIdentifier, GSZoomInItemIdentifier, GSZoomOutItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier];
  }
  else {
    return [NSArray array];
  }
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  if (toolbar == prefToolbar) {
    return @[GSToolbarPlayerInfoItemIdentifier, GSToolbarKeyConfigItemIdentifier];
  }
  else if (toolbar == boloToolbar) {
    return @[GSBoloToolItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, GSTankCenterItemIdentifier, GSPillCenterItemIdentifier, NSToolbarSeparatorItemIdentifier, GSZoomInItemIdentifier, GSZoomOutItemIdentifier];
  }
  else {
    return [NSArray array];
  }
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  if (toolbar == prefToolbar) {
    return @[GSToolbarPlayerInfoItemIdentifier, GSToolbarKeyConfigItemIdentifier];
  }
  else if (toolbar == boloToolbar) {
    return [NSArray array];
  }
  else {
    return [NSArray array];
  }
}

// NSWindow delegate methods
- (void)windowDidBecomeKey:(NSNotification *)aNotification {
  if (aNotification.object == statusPanel) {
    [self setShowStatus:YES];
  }
  else if (aNotification.object == allegiancePanel) {
    [self setShowAllegiance:YES];
  }
  else if (aNotification.object == messagesPanel) {
    [self setShowMessages:YES];
  }
}

- (void)windowWillClose:(NSNotification *)aNotification {
  if (aNotification.object == statusPanel) {
    [self setShowStatus:NO];
  }
  else if (aNotification.object == allegiancePanel) {
    [self setShowAllegiance:NO];
  }
  else if (aNotification.object == messagesPanel) {
    [self setShowMessages:NO];
  }
  else if (aNotification.object == boloWindow) {
    if (client_running) {
      [self closeGame:self];
    }
  }
}

- (void)setPlayerStatus:(NSString *)aString {
  NSEnumerator *enumerator;
  NSAttributedString *name;
  NSMutableDictionary *playerRecord;
  NSString *indexString;
  NSImageView *imageView;
  int gotlock = 0;
  int player;

TRY
  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  player = aString.intValue;

  switch (player) {
  case 0x0:
    imageView = player0StatusImageView;
    break;

  case 0x1:
    imageView = player1StatusImageView;
    break;

  case 0x2:
    imageView = player2StatusImageView;
    break;

  case 0x3:
    imageView = player3StatusImageView;
    break;

  case 0x4:
    imageView = player4StatusImageView;
    break;

  case 0x5:
    imageView = player5StatusImageView;
    break;

  case 0x6:
    imageView = player6StatusImageView;
    break;

  case 0x7:
    imageView = player7StatusImageView;
    break;

  case 0x8:
    imageView = player8StatusImageView;
    break;

  case 0x9:
    imageView = player9StatusImageView;
    break;

  case 0xa:
    imageView = playerAStatusImageView;
    break;

  case 0xb:
    imageView = playerBStatusImageView;
    break;

  case 0xc:
    imageView = playerCStatusImageView;
    break;

  case 0xd:
    imageView = playerDStatusImageView;
    break;

  case 0xe:
    imageView = playerEStatusImageView;
    break;

  case 0xf:
    imageView = playerFStatusImageView;
    break;

  default:
    imageView = nil;
    break;
  }

  indexString = [NSString stringWithFormat:@"%d", player];

  if (client.players[player].connected) {
    enumerator = [playerInfoArray objectEnumerator];

    while ((playerRecord = [enumerator nextObject])) {
      if ([playerRecord[@"Index"] isEqualToString:indexString]) {
        break;
      }
    }

    if (playerRecord == nil) {
      playerRecord = [[NSMutableDictionary alloc] init];
      [playerInfoArray addObject:playerRecord];
    }

    playerRecord[@"Index"] = indexString;

    NSColor *backgroundColor = nil;
    NSString *alliance = nil;

    if (client.player == player) {
      NSFont *boldFont = playerInfoTableView.font ?
        [[NSFontManager sharedFontManager] convertFont:playerInfoTableView.font toHaveTrait:NSFontBoldTrait] :
        [NSFont boldSystemFontOfSize:[NSFont systemFontSize]];
      name = [[NSAttributedString alloc] initWithString:@(client.players[player].name) attributes:@{NSFontAttributeName: boldFont}];
    } else if (client.players[client.player].seq - client.players[player].lastupdate >= 3*TICKSPERSEC) {
      name = [[NSAttributedString alloc] initWithString:@(client.players[player].name) attributes:@{NSForegroundColorAttributeName: [NSColor whiteColor]}];
      backgroundColor = [NSColor redColor];
    }
    else if (client.players[client.player].seq - client.players[player].lastupdate >= TICKSPERSEC) {
      name = [[NSAttributedString alloc] initWithString:@(client.players[player].name) attributes:@{}];
      backgroundColor = [NSColor yellowColor];
    } else {
      name = [[NSAttributedString alloc] initWithString:@(client.players[player].name) attributes:@{}];
    }

    if (client.player == player) {
      alliance = @"You";
    } else if (testalliance(client.player, player)) {
      alliance = @"Ally";
    } else if (requestedalliance(client.player, player)) {
      alliance = @"Requested";
    } else if (requestedalliance(player, client.player)) {
      alliance = @"Received";
    }

    playerRecord[@"Player"] = name;
    playerRecord[@"BackgroundColor"] = backgroundColor;
    playerRecord[@"Alliance"] = alliance;

    if (client.player == player) {
      imageView.image = [NSImage imageNamed:@"PlayerStatFriendly"];
    }
    else if (
      (client.players[client.player].alliance & (1 << player)) &&
      (client.players[player].alliance & (1 << client.player))
    ) {
      imageView.image = [NSImage imageNamed:@"PlayerStatAlliedFriendly"];
    }
    else {
      imageView.image = [NSImage imageNamed:@"PlayerStatHostile"];
    }
  }
  else {
    enumerator = [playerInfoArray objectEnumerator];

    while ((playerRecord = [enumerator nextObject])) {
      if ([playerRecord[@"Index"] isEqualToString:indexString]) {
        [playerInfoArray removeObject:playerRecord];
        break;
      }
    }

    [imageView setImage:nil];
  }

  [playerInfoTableView reloadData];
  [self updateTableButtons:playerInfoTableView];

  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    if (gotlock) {
      unlockclient();
    }

    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)setPillStatus:(NSString *)aString {
  NSImageView *imageView;
  int gotlock = 0;
  int pill;

TRY
  pill = aString.intValue;

  switch (pill) {
  case 0x0:
    imageView = pill0StatusImageView;
    break;

  case 0x1:
    imageView = pill1StatusImageView;
    break;

  case 0x2:
    imageView = pill2StatusImageView;
    break;

  case 0x3:
    imageView = pill3StatusImageView;
    break;

  case 0x4:
    imageView = pill4StatusImageView;
    break;

  case 0x5:
    imageView = pill5StatusImageView;
    break;

  case 0x6:
    imageView = pill6StatusImageView;
    break;

  case 0x7:
    imageView = pill7StatusImageView;
    break;

  case 0x8:
    imageView = pill8StatusImageView;
    break;

  case 0x9:
    imageView = pill9StatusImageView;
    break;

  case 0xa:
    imageView = pillAStatusImageView;
    break;

  case 0xb:
    imageView = pillBStatusImageView;
    break;

  case 0xc:
    imageView = pillCStatusImageView;
    break;

  case 0xd:
    imageView = pillDStatusImageView;
    break;

  case 0xe:
    imageView = pillEStatusImageView;
    break;

  case 0xf:
    imageView = pillFStatusImageView;
    break;

  default:
    imageView = nil;
    break;
  }

  if (lockclient()) LOGFAIL(errno)

  if (pill < client.npills) {
    switch (client.pills[pill].armour) {
    case 0:
      imageView.image = [NSImage imageNamed:@"PillStatDead"];
      break;

    case ONBOARD:
      if (client.pills[pill].owner == client.player) {
        imageView.image = [NSImage imageNamed:@"PillStatIntFriendly"];
      }
      else if (
        client.pills[pill].owner != NEUTRAL &&
        (
          (client.players[client.pills[pill].owner].alliance & (1 << client.player)) &&
          (client.players[client.player].alliance & (1 << client.pills[pill].owner))
        )
      ) {
        imageView.image = [NSImage imageNamed:@"PillStatIntAllied"];
      }
      else {
        imageView.image = [NSImage imageNamed:@"PillStatIntHostile"];
      }

      break;

    default:
      if (client.pills[pill].owner == client.player) {
        imageView.image = [NSImage imageNamed:@"PillStatFriendly"];
      }
      else if (client.pills[pill].owner == NEUTRAL) {
        imageView.image = [NSImage imageNamed:@"PillStatNeutral"];
      }
      else if (
        client.pills[pill].owner != NEUTRAL &&
        (
          (client.players[client.pills[pill].owner].alliance & (1 << client.player)) &&
          (client.players[client.player].alliance & (1 << client.pills[pill].owner))
        )
      ) {
        imageView.image = [NSImage imageNamed:@"PillStatFriendly"];
      }
      else {
        imageView.image = [NSImage imageNamed:@"PillStatHostile"];
      }

      break;
    }
  }
  else {
    [imageView setImage:nil];
  }

  if (unlockclient()) LOGFAIL(errno)

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    if (gotlock) {
      unlockclient();
    }

    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)setBaseStatus:(NSString *)aString {
  NSImageView *imageView;
  int gotlock = 0;
  int base;

TRY
  if (lockclient()) LOGFAIL(errno)
  gotlock = 1;

  base = aString.intValue;

  switch (base) {
  case 0x0:
    imageView = base0StatusImageView;
    break;

  case 0x1:
    imageView = base1StatusImageView;
    break;

  case 0x2:
    imageView = base2StatusImageView;
    break;

  case 0x3:
    imageView = base3StatusImageView;
    break;

  case 0x4:
    imageView = base4StatusImageView;
    break;

  case 0x5:
    imageView = base5StatusImageView;
    break;

  case 0x6:
    imageView = base6StatusImageView;
    break;

  case 0x7:
    imageView = base7StatusImageView;
    break;

  case 0x8:
    imageView = base8StatusImageView;
    break;

  case 0x9:
    imageView = base9StatusImageView;
    break;

  case 0xa:
    imageView = baseAStatusImageView;
    break;

  case 0xb:
    imageView = baseBStatusImageView;
    break;

  case 0xc:
    imageView = baseCStatusImageView;
    break;

  case 0xd:
    imageView = baseDStatusImageView;
    break;

  case 0xe:
    imageView = baseEStatusImageView;
    break;

  case 0xf:
    imageView = baseFStatusImageView;
    break;

  default:
    assert(0);
    break;
  }

  if (base < client.nbases) {
    if (client.bases[base].owner == NEUTRAL) {
      imageView.image = [NSImage imageNamed:@"BaseStatNeutral"];
    }
    else if (client.bases[base].armour < MINBASEARMOUR) {
      imageView.image = [NSImage imageNamed:@"BaseStatDead"];
    }
    else if (client.bases[base].owner == client.player) {
      imageView.image = [NSImage imageNamed:@"BaseStatFriendly"];
    }
    else if (
      client.bases[base].owner != NEUTRAL &&
      (
        (client.players[client.bases[base].owner].alliance & (1 << client.player)) &&
        (client.players[client.player].alliance & (1 << client.bases[base].owner))
      )
    ) {
      imageView.image = [NSImage imageNamed:@"BaseStatFriendly"];
    }
    else {
      imageView.image = [NSImage imageNamed:@"BaseStatHostile"];
    }
  }
  else {
    [imageView setImage:nil];
  }

  if (unlockclient()) LOGFAIL(errno)
  gotlock = 0;

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    if (gotlock) {
      unlockclient();
    }

    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)setTankStatusBars {
  playerKillsTextField.stringValue = [NSString stringWithFormat:@"%d", client.kills];
  playerDeathsTextField.stringValue = [NSString stringWithFormat:@"%d", client.deaths];
  playerShellsStatusBar.value = ((CGFloat)client.shells)/MAXSHELLS;
  playerMinesStatusBar.value = ((CGFloat)client.mines)/MAXMINES;
  playerArmourStatusBar.value = ((CGFloat)client.armour)/MAXARMOUR;
  playerTreesStatusBar.value = ((CGFloat)client.trees)/MAXTREES;
}

- (void)refresh:(NSTimer *)aTimer {
  int i;
  int base = -1;
  CGFloat dist = 8.0, dist2;
  BOOL gotlock = 0;
  static int counter = 0;

TRY
  if (client_running) {
    counter++;

    if (lockclient()) LOGFAIL(errno)
    gotlock = 1;

    if (client.player != -1) {
      /* make sure tank is visible if just spawned */
      int centerTank = 0;
      if (client.spawned) {
        if(client.deaths == 0)
          centerTank = 1; // center it if this is the very first spawn
        else
        {
          NSRect rect;
          rect.size.width = rect.size.height = 16 * 16 * kZoomLevels[zoomLevel];
          rect.origin.x = ((client.players[client.player].tank.x + 0.5)*16.0) - rect.size.width*0.5;
          rect.origin.y = ((FWIDTH - (client.players[client.player].tank.y + 0.5))*16.0) - rect.size.height*0.5;

          [boloView scrollToVisible:client.players[client.player].tank];
        }
        if (unlockclient()) LOGFAIL(errno)
        gotlock = 0;

        client.spawned = 0;
      }
      if(centerTank)
        [self tankCenter:nil];
      [GSBoloViews refresh];

      if (counter%2) {
        switch (client.players[client.player].builderstatus) {
        case kBuilderGoto:
        case kBuilderWork:
        case kBuilderWait:
        case kBuilderReturn:
          {
            Vec2f diff;
            float newdir;
          
            diff = sub2f(client.players[client.player].builder, client.players[client.player].tank);
            newdir = vec2dir(diff);
          
            builderStatusView.state = GSBuilderStatusViewStateDirection;
            builderStatusView.direction = newdir;
          }
          
          break;
          
        case kBuilderParachute:
          builderStatusView.state = GSBuilderStatusViewStateDead;
          break;
          
        case kBuilderReady:
          builderStatusView.state = GSBuilderStatusViewStateReady;
          break;
          
        default:
          assert(0);
          break;
        }
      
        // update base status bars
        for (i = 0; i < client.nbases; i++) {
          if (
              client.bases[i].owner != NEUTRAL &&
              (client.players[client.bases[i].owner].alliance & (1 << client.player)) &&
              (client.players[client.player].alliance & (1 << client.bases[i].owner))
              ) {
            dist2 = mag2f(sub2f(client.players[client.player].tank, make2f(client.bases[i].x + 0.5, client.bases[i].y + 0.5)));
          
            if (dist2 < dist) {
              base = i;
              dist = dist2;
            }
          }
        }
      
        if (base != -1) {
          baseArmourStatusBar.value = (CGFloat)client.bases[base].armour/(CGFloat)MAX_BASE_ARMOUR;
          baseShellsStatusBar.value = (CGFloat)client.bases[base].shells/(CGFloat)MAX_BASE_SHELLS;
          baseMinesStatusBar.value = (CGFloat)client.bases[base].mines/(CGFloat)MAX_BASE_MINES;
        }
        else {
          baseShellsStatusBar.value = 0.0;
          baseMinesStatusBar.value = 0.0;
          baseArmourStatusBar.value = 0.0;
        }
      }
    }

    if (unlockclient()) LOGFAIL(errno)
    gotlock = 0;
  }

CLEANUP
  switch (ERROR) {
  case 0:
    break;

  default:
    if (gotlock) {
      unlockclient();
    }

    PCRIT(ERROR)
    printlineinfo();
    CLEARERRLOG
    exit(EXIT_FAILURE);
    break;
  }
END
}

- (void)printMessage:(NSAttributedString *)aString {
  NSAttributedString *newline;

  newline = [[NSAttributedString alloc] initWithString:@"\n"];
  [messagesTextView.textStorage appendAttributedString:newline];
  [messagesTextView.textStorage appendAttributedString:aString];
  [messagesTextView didChangeText];
  [messagesTextView scrollPoint:NSMakePoint(0.0f, NSHeight(messagesTextView.frame) - NSHeight(messagesTextView.visibleRect))];

//  int i;
//  if (!muteBool) {
//    for (i = 0; i < [speechSynthesizers count]; i++) {
//      NSSpeechSynthesizer *speechSynthesizer;
//
//      speechSynthesizer = [speechSynthesizers objectAtIndex:i];
//
//      if (![speechSynthesizer isSpeaking]) {
//        [speechSynthesizer startSpeakingString:[aString string]];
//        break;
//      }
//    }
//  }
	
}

- (void)updateTableButtons:(NSTableView *)table {
  NSInteger i;
  NSDictionary *row;

  if (table == playerInfoTableView) {
    if (table.numberOfSelectedRows == 0) {
      [requestAllianceButton setEnabled:FALSE];
      [leaveAllianceButton setEnabled:FALSE];
    }
    else {
      BOOL currentPlayerSelected = NO;
      BOOL allySelected = NO;
      BOOL allyRequestedSelected = NO;
      BOOL enemySelected = NO;

      NSIndexSet *set = playerInfoTableView.selectedRowIndexes;
      for (i = 0; (i = [set indexGreaterThanOrEqualToIndex:i]) != NSNotFound; i++) {
        int player = [playerInfoArray[i][@"Index"] intValue];
        if (player == client.player) {
          currentPlayerSelected = YES;
        } else if (testalliance(client.player, player)) {
          allySelected = YES;
        } else if (requestedalliance(client.player, player)) {
          allyRequestedSelected = YES;
        } else {
          enemySelected = YES;
        }
      }

      [requestAllianceButton setEnabled:enemySelected];
      [leaveAllianceButton setEnabled:allySelected || allyRequestedSelected];
    }
  }
  else if (table == joinTrackerTableView) {
    i = table.selectedRowIndexes.firstIndex;

    if (i != NSNotFound) {
      row = joinTrackerArray[i];
      [self setJoinAddress:row[GSHostnameColumn]];
      [self setJoinPort:[row[GSPortColumn] intValue]];
    }
  }
}

// NSTableView delegate methods

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  NSTableView *table;

  table = aNotification.object;
  [self updateTableButtons:table];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
  if (aTableView == playerInfoTableView) {
    NSParameterAssert(rowIndex >= 0 && rowIndex < [playerInfoArray count]);
    if ([@"Player" isEqualToString:tableColumn.identifier]) {
      if (playerInfoArray[rowIndex][@"BackgroundColor"]) {
        [cell setBackgroundColor:playerInfoArray[rowIndex][@"BackgroundColor"]];
        [cell setDrawsBackground:YES];
      } else {
        [cell setDrawsBackground:NO];
      }
    }
  }
}


// NSTableView dataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  if (aTableView == playerInfoTableView) {
    return playerInfoArray.count;
  }
  else if (aTableView == joinTrackerTableView) {
    return joinTrackerArray.count;
  }
  else {
    return 0;
  }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  if (aTableView == playerInfoTableView) {
    NSParameterAssert(rowIndex >= 0 && rowIndex < [playerInfoArray count]);
    return playerInfoArray[rowIndex][aTableColumn.identifier];
  }
  else if (aTableView == joinTrackerTableView) {
    NSParameterAssert(rowIndex >= 0 && rowIndex < [joinTrackerArray count]);
    if ([aTableColumn.identifier isEqualToString:GSSourceColumn]) {
      NSNumber *servSource = joinTrackerArray[rowIndex][GSSourceColumn];
      if (servSource.integerValue == GSServerSourceTracker) {
        return [NSImage imageNamed:@"XBolo"];
      } else /* GSServerSourceBonjour */{
        return [NSImage imageNamed:NSImageNameBonjour];
      }
    }
    return joinTrackerArray[rowIndex][aTableColumn.identifier];
  }
  else {
    return nil;
  }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  if (aTableView == playerInfoTableView) {
    NSParameterAssert(rowIndex >= 0 && rowIndex < [playerInfoArray count]);
    playerInfoArray[rowIndex][aTableColumn.identifier] = anObject;
  }
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
  if (aTableView == joinTrackerTableView) {  /* sorts joinTrackerArray */
    NSInteger index;
    NSDictionary *selection;

    index = aTableView.selectedRowIndexes.firstIndex;

    if (index != NSNotFound) {
      selection = joinTrackerArray[index];
    }

    [joinTrackerArray sortUsingDescriptors:aTableView.sortDescriptors];
    [aTableView reloadData];

    if (index != NSNotFound) {
      [aTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[joinTrackerArray indexOfObject:selection]] byExtendingSelection:NO];
    }
  }
}

//

- (void)setJoinProgressStatusTextField:(NSString *)aString {
  joinProgressStatusTextField.stringValue = aString;
}

- (void)setJoinProgressIndicator:(NSNumber *)aString {
  [joinProgressIndicator setIndeterminate:NO];
  joinProgressIndicator.doubleValue = aString.doubleValue;
}

- (void)joinSuccess {
  [boloView setNeedsDisplay:YES];
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  [newGameWindow orderOut:self];
  [boloWindow makeKeyAndOrderFront:self];

  if (showStatusBool) {
    [statusPanel orderFront:self];
  }

  if (showAllegianceBool) {
    [allegiancePanel orderFront:self];
  }

  [messagesTextView.textStorage deleteCharactersInRange:NSMakeRange(0, messagesTextView.textStorage.length)];

  if (showMessagesBool) {
    [messagesPanel orderFront:self];
  }
}

- (void)joinDNSError:(NSString *)eString {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Error Resolving Hostname", @"Error Resolving Hostname");
  alert.informativeText = eString;
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinTimeOut {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Network Error", @"Network Error");
  alert.informativeText = NSLocalizedString(@"Connection establishment timed out without establishing a connection.", @"Connection establishment timed out without establishing a connection.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinConnectionRefused {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Network Error", @"Network Error");
  alert.informativeText = NSLocalizedString(@"The attempt to connect was forcefully rejected.", @"The attempt to connect was forcefully rejected.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinNetUnreachable {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Network Error", @"Network Error");
  alert.informativeText = NSLocalizedString(@"The network is not reachable from this host.", @"The network is not reachable from this host.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinHostUnreachable {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Network Error", @"Network Error");
  alert.informativeText = NSLocalizedString(@"The remote host is not reachable from this host.", @"The remote host is not reachable from this host.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinBadVersion {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Server Error", @"Server Error");
  alert.informativeText = NSLocalizedString(@"Server version doesn't match.", @"Server version doesn't match.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinDisallow {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Server Error", @"Server Error");
  alert.informativeText = NSLocalizedString(@"Host is not allowing new players in the game.", @"Host is not allowing new players in the game.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinBadPassword {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Server Error", @"Server Error");
  alert.informativeText = NSLocalizedString(@"Password rejected.", @"Password rejected.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinServerFull {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Server Error", @"Server Error");
  alert.informativeText = NSLocalizedString(@"Server is full.", @"Server is full.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinTimeLimit {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Server Error", @"Server Error");
  alert.informativeText = NSLocalizedString(@"Time limit reached on server.", @"Time limit reached on server.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinBannedPlayer {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Server Error", @"Server Error");
  alert.informativeText = NSLocalizedString(@"Host has banned you from the game.", @"Host has banned you from the game.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinServerError {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Server Error", @"Server Error");
  alert.informativeText = NSLocalizedString(@"Protocol error.", @"Protocol error.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)joinConnectionReset {
TRY
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Server Error", @"Server Error");
  alert.informativeText = NSLocalizedString(@"Connection Reset by Peer.", @"Connection Reset by Peer.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
  if (stopclient()) LOGFAIL(errno)

  if (server.setup) {
    if (stopserver()) LOGFAIL(errno)
  }

  [broadcaster startListening];

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

- (void)registerSuccess {
TRY
  if (startclient("localhost", getservertcpport(), playerNameString.UTF8String, hostPasswordBool ? hostPasswordString.UTF8String : NULL)) LOGFAIL(errno)
  [boloView reset];

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

- (void)trackerDNSError:(NSString *)eString {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Error Resolving Tracker", @"Error Resolving Tracker");
  alert.informativeText = eString;
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];

  [broadcaster startListening];

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

- (void)registerTrackerTimeOut {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Tracker Timed Out", @"Tracker Timed Out");
  alert.informativeText = NSLocalizedString(@"Could not connect to the tracker.", @"Could not connect to the tracker.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];

  [broadcaster startListening];

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

- (void)registerTrackerConnectionRefused {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Tracker Connection Refused", @"Tracker Connection Refused");
  alert.informativeText = NSLocalizedString(@"Connection was refused by the tracker.", @"Connection was refused by the tracker.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];

  [broadcaster startListening];

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

- (void)registerTrackerHostDown {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Tracker Host Down", @"Tracker Host Down");
  alert.informativeText = NSLocalizedString(@"Tracker is not responding.", @"Tracker is not responding.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];

  [broadcaster startListening];

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

- (void)registerTrackerHostUnreachable {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Tracker Host Unreachable", @"Tracker Host Unreachable");
  alert.informativeText = NSLocalizedString(@"Check your network connectivity.", @"Check your network connectivity.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];

  [broadcaster startListening];

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

- (void)registerTrackerBadVersion {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Incompatible Version", @"Incompatible Version");
  alert.informativeText = NSLocalizedString(@"Check your network connectivity.", @"Check your network connectivity.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];

  [broadcaster startListening];

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

- (void)registerTrackerTCPPortBlocked {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Failed to Verify TCP Port Forwarded", @"Failed to Verify TCP Port Forwarded");
  alert.informativeText = NSLocalizedString(@"Try setting up port forwarding in your router.  If you have port forwarding setup in your router, uncheck UPnP and try again.", @"Try setting up port forwarding in your router.  If you have port forwarding setup in your router, uncheck UPnP and try again.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];

  [broadcaster startListening];

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

- (void)registerTrackerUDPPortBlocked {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Failed to Verify UDP Port Forwarded", @"Failed to Verify UDP Port Forwarded");
  alert.informativeText = NSLocalizedString(@"Try setting up port forwarding in your router.  If you have port forwarding setup in your router, uncheck UPnP and try again.", @"Try setting up port forwarding in your router.  If you have port forwarding setup in your router, uncheck UPnP and try again.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];

  [broadcaster startListening];

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

- (void)registerTrackerConnectionReset {
TRY
  if (stopserver()) LOGFAIL(errno)
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Connection Error", @"Connection Error");
  alert.informativeText = NSLocalizedString(@"Connection Reset by Peer.", @"Connection Reset by Peer.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];

  [broadcaster startListening];

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

- (void)getListTrackerTimeOut {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Tracker Timed Out", @"Tracker Timed Out");
  alert.informativeText = NSLocalizedString(@"Could not connect to the tracker.", @"Could not connect to the tracker.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
}

- (void)getListTrackerConnectionRefused {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Tracker Connection Refused", @"Tracker Connection Refused");
  alert.informativeText = NSLocalizedString(@"Connection was refused by the tracker.", @"Connection was refused by the tracker.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
}

- (void)getListTrackerHostDown {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Tracker Host Down", @"Tracker Host Down");
  alert.informativeText = NSLocalizedString(@"Tracker is not responding.", @"Tracker is not responding.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
}

- (void)getListTrackerHostUnreachable {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Tracker Host Unreachable", @"Tracker Host Unreachable");
  alert.informativeText = NSLocalizedString(@"Check your network connectivity.", @"Check your network connectivity.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
}

- (void)getListTrackerBadVersion {
  stoptracker();
  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = NSLocalizedString(@"Incompatible Version", @"Incompatible Version");
  alert.informativeText = NSLocalizedString(@"Tracker version doesn't match.", @"Tracker version doesn't match.");
  [alert beginSheetModalForWindow:newGameWindow completionHandler:^(NSModalResponse returnCode) {
    //do nothing
  }];
}

- (void)getListTrackerSuccess {
  NSMutableArray *table;
  NSArray *keys, *objects;
  struct ListNode *node;

  stoptracker();

  [joinProgressWindow orderOut:self];
  [joinProgressIndicator stopAnimation:self];
  [newGameWindow endSheet:joinProgressWindow];

  // convert list to NSArray for displaying
  table = [NSMutableArray array];
  keys = @[GSHostPlayerColumn, GSMapNameColumn, GSPlayersColumn, GSPasswordColumn, GSAllowJoinColumn, GSPausedColumn, GSHostnameColumn, GSPortColumn, GSSourceColumn];
  NSNumber *sourceTracker = @(GSServerSourceTracker);

  for (node = nextlist(&trackerlist); node; node = nextlist(node)) {
    struct TrackerHostList *hostlist;
    hostlist = ptrlist(node);

    objects = @[@((char *)hostlist->game.playername),
      @((char *)hostlist->game.mapname),
      [NSString stringWithFormat:@"%d", hostlist->game.nplayers],
      hostlist->game.passreq ? @"Yes" : @"No",
      hostlist->game.allowjoin ? @"Yes" : @"No",
      hostlist->game.pause ? @"Yes" : @"No",
      @(inet_ntoa(hostlist->addr)),
      [NSString stringWithFormat:@"%d", hostlist->game.port],
      sourceTracker];
    [table addObject:[NSDictionary dictionaryWithObjects:objects forKeys:keys]];
  }

  // free list
  clearlist(&trackerlist, free);

  // update table
  [self setJoinTrackerArray:table];
}

// robots!

- (BOOL)_validateRobotMenuItem: (NSMenuItem *)item
{
    [robotLock lock];
    item.state = item.representedObject == robot ? NSOnState : NSOffState;
    [robotLock unlock];
    return YES;
}

- (void)choseRobotMenuItem: (id)sender
{
    GSRobot *newRobot = [sender representedObject];
    [robotLock lock];
    if(newRobot != robot)
    {
      NSError *err;
        if(![newRobot loadWithError:&err])
        {
            [NSApp presentError: err];
        }
        else
        {
            [robot unload];
            robot = newRobot;
        }
    }
    [robotLock unlock];
}

- (void)setupRobotsMenu
{
    NSArray<GSRobot*> *robots = [GSRobot availableRobots];
    
    NSMenuItem *autoMenu = nil;
    NSString *autoName = [[NSUserDefaults standardUserDefaults] stringForKey: @"GSAutomaticallyLoadRobot"];
    
    if(robots.count)
    {
        NSMenu *menu = [[NSMenu alloc] initWithTitle: @"Robots"];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: @"Manual Control" action: @selector(choseRobotMenuItem:) keyEquivalent: @""];
        [menu addItem: item];
        
        [menu addItem: [NSMenuItem separatorItem]];
        
        for(GSRobot *r in robots)
        {
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: r.name action: @selector(choseRobotMenuItem:) keyEquivalent: @""];
            item.representedObject = r;
            [menu addItem: item];
            if(autoName && [r.name hasPrefix: autoName])
                autoMenu = item;
        }
        
        NSMenuItem *robotItem = [[NSMenuItem alloc] initWithTitle: @"Robots" action: NULL keyEquivalent: @""];
        robotItem.submenu = menu;
        [NSApp.mainMenu addItem: robotItem];
    }
    
    if(autoMenu)
        [self choseRobotMenuItem: autoMenu];
}

- (void)clientLoopUpdate
{
    @autoreleasepool {
        [robotLock lock];
        [robot step];
        [robotLock unlock];
    }
}

- (void)sendMessageToRobot: (NSString *)string
{
    [robotLock lock];
    NSString *myPrefix = [NSString stringWithFormat: @"%s:", client.name];
    if(![string hasPrefix: myPrefix])
      [robot receivedMessage: string];
    [robotLock unlock];
}    

- (void)requestConnectionToServer:(NSString*)servStr port:(unsigned short)port password:(NSString *)pass
{
  self.joinPort = port;
  self.joinAddress = servStr;
  if (pass) {
    self.joinPasswordEnabled = YES;
    self.joinPassword = pass;
  } else {
    self.joinPasswordEnabled = NO;
  }
}

@synthesize broadcastBonjour = _broadcastBonjour;

- (void)setBroadcastBonjour:(BOOL)broadcastBonjour
{
  _broadcastBonjour = broadcastBonjour;
  if (broadcaster && !_broadcastBonjour) {
    [broadcaster stopPublishing];
  } else if (server.running && _broadcastBonjour) {
    [broadcaster startPublishing];
  }
}

- (IBAction)hostToggleBonjourBroadcast:(nullable id)sender
{
  self.broadcastBonjour = !_broadcastBonjour;
}

- (IBAction)joinToggleBonjourListen:(nullable NSButton*)sender
{
  if (broadcaster.listening) {
    [broadcaster stopListening];
    sender.state = NSOffState;
  } else {
    [broadcaster startListening];
    sender.state = NSOnState;
  }
}

- (void)clearBonjourEntries {
  NSMutableIndexSet *mutSet = [NSMutableIndexSet indexSet];
  for (NSInteger i = 0; i < joinTrackerArray.count; i++) {
    if ([joinTrackerArray[i][GSSourceColumn] isEqual:@(GSServerSourceBonjour)]) {
      [mutSet addIndex:i];
    }
  }
  [joinTrackerArray removeObjectsAtIndexes:mutSet];
  [self setJoinTrackerArray:joinTrackerArray];
}

@end

void setplayerstatus(int player) {
  assert(player >= 0 && player < MAX_PLAYERS);
  @autoreleasepool {
    [controller performSelectorOnMainThread:@selector(setPlayerStatus:) withObject:[NSString stringWithFormat:@"%d", player] waitUntilDone:NO];
  }
}

void setpillstatus(int pill) {
  assert(pill >= 0 && pill < MAX_PILLS);
  @autoreleasepool {
    [controller performSelectorOnMainThread:@selector(setPillStatus:) withObject:[NSString stringWithFormat:@"%d", pill] waitUntilDone:NO];
  }
}

void setbasestatus(int base) {
  assert(base >= 0 && base < MAX_BASES);
  @autoreleasepool {
    [controller performSelectorOnMainThread:@selector(setBaseStatus:) withObject:[NSString stringWithFormat:@"%d", base] waitUntilDone:NO];
  }
}

void settankstatus() {
  @autoreleasepool {
    [controller performSelectorOnMainThread:@selector(setTankStatusBars) withObject:nil waitUntilDone:NO];
  }
}

void playsound(int snd) {
  if (!muteGlobal) {
    int i;
    NSArray *array;

    @autoreleasepool {

      switch (snd) {
      case kBubblesSound:
        array = bubblessounds;
        break;

      case kBuildSound:
        array = buildsounds;
        break;

      case kBuilderDeathSound:
        array = builderdeathsounds;
        break;

      case kExplosionSound:
        array = explosionsounds;
        break;

      case kFarBuildSound:
        array = farbuildsounds;
        break;

      case kFarBuilderDeathSound:
        array = farbuilderdeathsounds;
        break;

      case kFarExplosionSound:
        array = farexplosionsounds;
        break;

      case kFarHitTankSound:
        array = farhittanksounds;
        break;

      case kFarHitTerrainSound:
        array = farhitterrainsounds;
        break;

      case kFarHitTreeSound:
        array = farhittreesounds;
        break;

      case kFarShotSound:
        array = farshotsounds;
        break;

      case kFarSinkSound:
        array = farsinksounds;
        break;

      case kFarSuperBoomSound:
        array = farsuperboomsounds;
        break;

      case kFarTreeSound:
        array = fartreesounds;
        break;

      case kHitTankSound:
        array = hittanksounds;
        break;

      case kHitTerrainSound:
        array = hitterrainsounds;
        break;

      case kHitTreeSound:
        array = hittreesounds;
        break;

      case kMineSound:
        array = minesounds;
        break;
			
	case kMsgReceivedSound:
	  array = msgreceivedsounds;
	  break;

      case kPillShotSound:
        array = pillshotsounds;
        break;

      case kSinkSound:
        array = sinksounds;
        break;

      case kSuperBoomSound:
        array = superboomsounds;
        break;

      case kTankShotSound:
        array = tankshotsounds;
        break;

      case kTreeSound:
        array = treesounds;
        break;

      default:
        array = nil;
        break;
      }

      // start playing sound
      for (i = 0; i < array.count; i++) {
        if (![array[i] isPlaying]) {
          [array[i] play];
          break;
        }
      }

    }
  }
}

void printmessage(int type, const char *text) {
  NSDictionary *attr;
  NSAttributedString *attrstring;

  assert(type == MSGEVERYONE || type == MSGALLIES || type == MSGNEARBY || type == MSGGAME);

  @autoreleasepool {

    switch (type) {
    case MSGEVERYONE:
      attr = [[NSDictionary alloc] init];
      break;

    case MSGALLIES:
      attr = @{NSForegroundColorAttributeName: [NSColor purpleColor]};
      break;

    case MSGNEARBY:
      attr = @{NSForegroundColorAttributeName: [NSColor redColor]};
      break;

    case MSGGAME:
      attr = @{NSForegroundColorAttributeName: [NSColor blueColor]};
      break;

    default:
      assert(0);
      break;
    }

    NSString *string = @(text);
    attrstring = [[NSAttributedString alloc] initWithString:string attributes:attr];
    [controller performSelectorOnMainThread:@selector(printMessage:) withObject:attrstring waitUntilDone:NO];

    if(type == MSGEVERYONE || type == MSGALLIES || type == MSGNEARBY) {
	playsound(kMsgReceivedSound);
	[controller sendMessageToRobot: string];
    }
    
  }
}

void joinprogress(int statuscode, float progress) {
  @autoreleasepool {
    switch (statuscode) {
    /* status udpates */
    case kJoinRESOLVING:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Resolving Hostname...", @"Resolving Hostname...") waitUntilDone:NO];
      break;

    case kJoinCONNECTING:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Connecting...", @"Connecting...") waitUntilDone:NO];
      break;

    case kJoinSENDJOIN:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Sending Client Data", @"Sending Client Data") waitUntilDone:NO];
      break;

    case kJoinRECVPREAMBLE:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Receiving Server Data", @"Receiving Server Data") waitUntilDone:NO];
      break;

    case kJoinRECVMAP:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Receving Map Data", @"Receving Map Data") waitUntilDone:NO];
      [controller performSelectorOnMainThread:@selector(setJoinProgressIndicator:) withObject:@(progress) waitUntilDone:NO];
      break;

    case kJoinSUCCESS:
      [controller performSelectorOnMainThread:@selector(joinSuccess) withObject:nil waitUntilDone:NO];
      break;

    /* errors */
    case kJoinEHOSTNOTFOUND:
      [controller performSelectorOnMainThread:@selector(joinDNSError:) withObject:@(hstrerror(HOST_NOT_FOUND)) waitUntilDone:NO];
      break;

    case kJoinEHOSTNORECOVERY:
      [controller performSelectorOnMainThread:@selector(joinDNSError:) withObject:@(hstrerror(NO_RECOVERY)) waitUntilDone:NO];
      break;

    case kJoinEHOSTNODATA:
      [controller performSelectorOnMainThread:@selector(joinDNSError:) withObject:@(hstrerror(NO_DATA)) waitUntilDone:NO];
      break;

    case kJoinETIMEOUT:
      [controller performSelectorOnMainThread:@selector(joinTimeOut) withObject:nil waitUntilDone:NO];
      break;

    case kJoinECONNREFUSED:
      [controller performSelectorOnMainThread:@selector(joinConnectionRefused) withObject:nil waitUntilDone:NO];
      break;

    case kJoinENETUNREACH:
      [controller performSelectorOnMainThread:@selector(joinNetUnreachable) withObject:nil waitUntilDone:NO];
      break;

    case kJoinEHOSTUNREACH:
      [controller performSelectorOnMainThread:@selector(joinHostUnreachable) withObject:nil waitUntilDone:NO];
      break;

    case kJoinEBADVERSION:
      [controller performSelectorOnMainThread:@selector(joinBadVersion) withObject:nil waitUntilDone:NO];
      break;

    case kJoinEDISALLOW:
      [controller performSelectorOnMainThread:@selector(joinDisallow) withObject:nil waitUntilDone:NO];
      break;

    case kJoinEBADPASS:
      [controller performSelectorOnMainThread:@selector(joinBadPassword) withObject:nil waitUntilDone:NO];
      break;

    case kJoinESERVERFULL:
      [controller performSelectorOnMainThread:@selector(joinServerFull) withObject:nil waitUntilDone:NO];
      break;

    case kJoinETIMELIMIT:
      [controller performSelectorOnMainThread:@selector(joinTimeLimit) withObject:nil waitUntilDone:NO];
      break;

    case kJoinEBANNEDPLAYER:
      [controller performSelectorOnMainThread:@selector(joinBannedPlayer) withObject:nil waitUntilDone:NO];
      break;

    case kJoinESERVERERROR:
      [controller performSelectorOnMainThread:@selector(joinServerError) withObject:nil waitUntilDone:NO];
      break;

    case kJoinECONNRESET:
      [controller performSelectorOnMainThread:@selector(joinConnectionReset) withObject:nil waitUntilDone:NO];
      break;

    default:
      assert(0);
      break;
    }

  }
}

void registercallback(int status) {
  @autoreleasepool {
    switch (status) {
    case kRegisterRESOLVING:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Resolving Tracker...", @"Resolving Tracker...") waitUntilDone:NO];
      break;

    case kRegisterCONNECTING:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Connecting to Tracker...", @"Connecting to Tracker...") waitUntilDone:NO];
      break;

    case kRegisterSENDINGDATA:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Sending Data...", @"Sending Data...") waitUntilDone:NO];
      break;

    case kRegisterTESTINGTCP:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Testing TCP Port...", @"Testing TCP Port...") waitUntilDone:NO];
      break;

    case kRegisterTESTINGUDP:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Testing UDP Port...", @"Testing UDP Port...") waitUntilDone:NO];
      break;

    case kRegisterSUCCESS:
      [controller performSelectorOnMainThread:@selector(registerSuccess) withObject:nil waitUntilDone:NO];
      break;

    case kRegisterEHOSTNORECOVERY:
      [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(NO_RECOVERY)) waitUntilDone:NO];
      break;
    
    case kRegisterEHOSTNOTFOUND:
      [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(HOST_NOT_FOUND)) waitUntilDone:NO];
      break;

    case kRegisterEHOSTNODATA:
      [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(NO_DATA)) waitUntilDone:NO];
      break;

    case kRegisterETIMEOUT:
      [controller performSelectorOnMainThread:@selector(registerTrackerTimeOut) withObject:nil waitUntilDone:NO];
      break;

    case kRegisterECONNREFUSED:
      [controller performSelectorOnMainThread:@selector(registerTrackerConnectionRefused) withObject:nil waitUntilDone:NO];
      break;

    case kRegisterEHOSTDOWN:
      [controller performSelectorOnMainThread:@selector(registerTrackerHostDown) withObject:nil waitUntilDone:NO];
      break;

    case kRegisterEHOSTUNREACH:
      [controller performSelectorOnMainThread:@selector(registerTrackerHostUnreachable) withObject:nil waitUntilDone:NO];
      break;

    case kRegisterEBADVERSION:
      [controller performSelectorOnMainThread:@selector(registerTrackerBadVersion) withObject:nil waitUntilDone:NO];
      break;

    case kRegisterETCPCLOSED:
      [controller performSelectorOnMainThread:@selector(registerTrackerTCPPortBlocked) withObject:nil waitUntilDone:NO];
      break;

    case kRegisterEUDPCLOSED:
      [controller performSelectorOnMainThread:@selector(registerTrackerUDPPortBlocked) withObject:nil waitUntilDone:NO];
      break;

    case kRegisterECONNRESET:
      [controller performSelectorOnMainThread:@selector(registerTrackerConnectionReset) withObject:nil waitUntilDone:NO];
      break;

    default:
      assert(0);
      break;
    }

  }
}

void getlisttrackerstatus(int status) {
  @autoreleasepool {
    switch (status) {
    case kGetListTrackerRESOLVING:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Resolving Tracker...", @"Resolving Tracker...") waitUntilDone:NO];
      break;

    case kGetListTrackerCONNECTING:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Connecting to Tracker...", @"Connecting to Tracker...") waitUntilDone:NO];
      break;

    case kGetListTrackerGETTINGLIST:
      [controller performSelectorOnMainThread:@selector(setJoinProgressStatusTextField:) withObject:NSLocalizedString(@"Receving Game List...", @"Receving Game List...") waitUntilDone:NO];
      break;

    case kGetListTrackerSUCCESS:
      [controller performSelectorOnMainThread:@selector(getListTrackerSuccess) withObject:nil waitUntilDone:NO];
      break;

    case kGetListTrackerECONNABORTED:  // error caused by user cancel
      break;

    case kGetListTrackerEPIPE:
      break;

    case kGetListTrackerEHOSTNOTFOUND:  // error from dns lookup
      [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(HOST_NOT_FOUND)) waitUntilDone:NO];
      break;

    case kGetListTrackerEHOSTNORECOVERY:
      [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(NO_RECOVERY)) waitUntilDone:NO];
      break;

    case kGetListTrackerEHOSTNODATA:
      [controller performSelectorOnMainThread:@selector(trackerDNSError:) withObject:@(hstrerror(NO_DATA)) waitUntilDone:NO];
      break;

    case kGetListTrackerETIMEOUT:  // error caused by other factors
      [controller performSelectorOnMainThread:@selector(getListTrackerTimeOut) withObject:nil waitUntilDone:NO];
      break;

    case kGetListTrackerECONNREFUSED:
      [controller performSelectorOnMainThread:@selector(getListTrackerConnectionRefused) withObject:nil waitUntilDone:NO];
      break;

    case kGetListTrackerEHOSTDOWN:
      [controller performSelectorOnMainThread:@selector(getListTrackerHostDown) withObject:nil waitUntilDone:NO];
      break;

    case kGetListTrackerEHOSTUNREACH:
      [controller performSelectorOnMainThread:@selector(getListTrackerHostUnreachable) withObject:nil waitUntilDone:NO];
      break;

    case kGetListTrackerEBADVERSION:
      [controller performSelectorOnMainThread:@selector(getListTrackerBadVersion) withObject:nil waitUntilDone:NO];
      break;

    default:
      assert(0);
      break;
    }

  }
}

int setKey(NSMutableDictionary<NSString*,NSString*> *dict, NSWindow *win, GSKeyCodeField *field, NSString *newObject) {
  NSString *key;
  id object;
  key = field.stringValue;
  object = dict[key];

  if (object != nil) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(@"There is a key conflict.", @"There is a key conflict");
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"There is a conflict with %@ and %@.  Change one of them.", @"There is a conflict with %@ and %@.  Change one of them."), object, newObject];
    [alert beginSheetModalForWindow:win completionHandler:^(NSModalResponse returnCode) {
      //do nothing
    }];
    return -1;
  }
  else {
    dict[key] = newObject;
    return 0;
  }
}

void clientloopupdate(void)
{
  [controller clientLoopUpdate];
}
