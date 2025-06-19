/* GSXBoloController */

#import <Cocoa/Cocoa.h>
#include <sys/socket.h>
#import <TCMPortMapper/TCMPortMapper.h>

#include "vector.h"
#include "rect.h"
#include "bolo.h"
#include "server.h"
#include "client.h"

@class GSKeyCodeField, GSBoloView, GSRobot, GSStatusBar, GSBuilderStatusView;
@protocol GSBoloViewProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface GSXBoloController : NSObject <NSApplicationDelegate, NSToolbarDelegate, NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate> {
  IBOutlet NSWindow *newGameWindow;
  IBOutlet NSWindow *boloWindow;
  IBOutlet NSWindow *joinProgressWindow;
  IBOutlet NSWindow *preferencesWindow;
  IBOutlet NSTabView *newGameTabView;
  IBOutlet NSPanel *statusPanel;
  IBOutlet NSPanel *allegiancePanel;
  IBOutlet NSPanel *messagesPanel;

  IBOutlet NSMenuItem *gamePauseResumeMenuItem;

  // host game outlets
  IBOutlet NSTextField *hostMapField;
  IBOutlet NSButton *hostMapResetButton;
  IBOutlet NSButton *hostUPnPSwitch;
  IBOutlet NSTextField *hostPortField;
  IBOutlet NSButton *hostPasswordSwitch;
  IBOutlet NSSecureTextField *hostPasswordField;
  IBOutlet NSButton *hostTimeLimitSwitch;
  IBOutlet NSSlider *hostTimeLimitSlider;
  IBOutlet NSButton *hostHiddenMinesSwitch;
  IBOutlet NSTextField *hostHiddenMinesTextField;
  IBOutlet NSButton *hostTrackerSwitch;
  IBOutlet NSTextField *hostTrackerField;
  IBOutlet NSTextField *hostTimeLimitField;
  IBOutlet NSPopUpButton *hostGameTypeMenu;
  IBOutlet NSTabView *hostGameTypeTab;

  // host domination outlets
  IBOutlet NSMatrix *hostDominationTypeMatrix;
  IBOutlet NSSlider *hostDominationBaseControlSlider;
  IBOutlet NSTextField *hostDominationBaseControlField;

  // join game outlets
  IBOutlet NSTextField *joinAddressField;
  IBOutlet NSTextField *joinPortField;
  IBOutlet NSButton *joinPasswordSwitch;
  IBOutlet NSSecureTextField *joinPasswordField;
  IBOutlet NSTextField *joinTrackerField;
  IBOutlet NSTableView *joinTrackerTableView;

  // join progress controls
  IBOutlet NSTextField *joinProgressStatusTextField;
  IBOutlet NSProgressIndicator *joinProgressIndicator;

  // preference outlets
  IBOutlet NSTabView *prefTab;
  IBOutlet NSTextField *prefPlayerNameField;
  IBOutlet GSKeyCodeField *prefAccelerateField;
  IBOutlet GSKeyCodeField *prefBrakeField;
  IBOutlet GSKeyCodeField *prefTurnLeftField;
  IBOutlet GSKeyCodeField *prefTurnRightField;
  IBOutlet GSKeyCodeField *prefLayMineField;
  IBOutlet GSKeyCodeField *prefShootField;
  IBOutlet GSKeyCodeField *prefIncreaseAimField;
  IBOutlet GSKeyCodeField *prefDecreaseAimField;
  IBOutlet NSButton *prefAutoSlowdownSwitch;
  IBOutlet GSKeyCodeField *prefUpField;
  IBOutlet GSKeyCodeField *prefDownField;
  IBOutlet GSKeyCodeField *prefLeftField;
  IBOutlet GSKeyCodeField *prefRightField;
  IBOutlet GSKeyCodeField *prefTankViewField;
  IBOutlet GSKeyCodeField *prefPillViewField;

  // Main View Outlets
  IBOutlet NSView<GSBoloViewProtocol> *boloView;
  IBOutlet NSView *builderToolView;

  /* Status Window Outlets */
  IBOutlet NSImageView *player0StatusImageView;
  IBOutlet NSImageView *player1StatusImageView;
  IBOutlet NSImageView *player2StatusImageView;
  IBOutlet NSImageView *player3StatusImageView;
  IBOutlet NSImageView *player4StatusImageView;
  IBOutlet NSImageView *player5StatusImageView;
  IBOutlet NSImageView *player6StatusImageView;
  IBOutlet NSImageView *player7StatusImageView;
  IBOutlet NSImageView *player8StatusImageView;
  IBOutlet NSImageView *player9StatusImageView;
  IBOutlet NSImageView *playerAStatusImageView;
  IBOutlet NSImageView *playerBStatusImageView;
  IBOutlet NSImageView *playerCStatusImageView;
  IBOutlet NSImageView *playerDStatusImageView;
  IBOutlet NSImageView *playerEStatusImageView;
  IBOutlet NSImageView *playerFStatusImageView;

  IBOutlet NSImageView *pill0StatusImageView;
  IBOutlet NSImageView *pill1StatusImageView;
  IBOutlet NSImageView *pill2StatusImageView;
  IBOutlet NSImageView *pill3StatusImageView;
  IBOutlet NSImageView *pill4StatusImageView;
  IBOutlet NSImageView *pill5StatusImageView;
  IBOutlet NSImageView *pill6StatusImageView;
  IBOutlet NSImageView *pill7StatusImageView;
  IBOutlet NSImageView *pill8StatusImageView;
  IBOutlet NSImageView *pill9StatusImageView;
  IBOutlet NSImageView *pillAStatusImageView;
  IBOutlet NSImageView *pillBStatusImageView;
  IBOutlet NSImageView *pillCStatusImageView;
  IBOutlet NSImageView *pillDStatusImageView;
  IBOutlet NSImageView *pillEStatusImageView;
  IBOutlet NSImageView *pillFStatusImageView;

  IBOutlet NSImageView *base0StatusImageView;
  IBOutlet NSImageView *base1StatusImageView;
  IBOutlet NSImageView *base2StatusImageView;
  IBOutlet NSImageView *base3StatusImageView;
  IBOutlet NSImageView *base4StatusImageView;
  IBOutlet NSImageView *base5StatusImageView;
  IBOutlet NSImageView *base6StatusImageView;
  IBOutlet NSImageView *base7StatusImageView;
  IBOutlet NSImageView *base8StatusImageView;
  IBOutlet NSImageView *base9StatusImageView;
  IBOutlet NSImageView *baseAStatusImageView;
  IBOutlet NSImageView *baseBStatusImageView;
  IBOutlet NSImageView *baseCStatusImageView;
  IBOutlet NSImageView *baseDStatusImageView;
  IBOutlet NSImageView *baseEStatusImageView;
  IBOutlet NSImageView *baseFStatusImageView;

  IBOutlet GSStatusBar *baseShellsStatusBar;
  IBOutlet GSStatusBar *baseMinesStatusBar;
  IBOutlet GSStatusBar *baseArmourStatusBar;

  IBOutlet GSBuilderStatusView *builderStatusView;

  IBOutlet NSTextField *playerKillsTextField;
  IBOutlet NSTextField *playerDeathsTextField;
  IBOutlet GSStatusBar *playerShellsStatusBar;
  IBOutlet GSStatusBar *playerMinesStatusBar;
  IBOutlet GSStatusBar *playerArmourStatusBar;
  IBOutlet GSStatusBar *playerTreesStatusBar;

  // host pane data
  NSURL *hostMapURL;
  NSURL *defaultHostMapURL;
  unsigned short hostPortNumber;
  BOOL hostPasswordBool;
  BOOL hostUPnPBool;
  NSString *hostPasswordString;
  BOOL hostTimeLimitBool;
  NSString *hostTimeLimitString;
  BOOL hostHiddenMinesBool;
  BOOL hostTrackerBool;

  //! only supported type is domination
  int hostGameTypeNumber;

  // host domination data
  int hostDominationTypeNumber;
  NSString *hostDominationBaseControlString;

  // window visibility bools
  BOOL showStatusBool;
  BOOL showAllegianceBool;
  BOOL showMessagesBool;

  // join pane data
  NSString *joinAddressString;
  unsigned short joinPortNumber;
  BOOL joinPasswordBool;
  BOOL joinTrackerBool;
  NSString *joinPasswordString;
  NSMutableArray<NSDictionary<NSString*,id>*> *joinTrackerArray;

  //! tracker string
  NSString *trackerString;

  // pref objects
  NSToolbar *prefToolbar;
  NSToolbarItem *toolbarPlayerInfoItem;
  NSToolbarItem *toolbarKeyConfigItem;
  NSString *playerNameString;
  NSDictionary *keyConfigDict;
  BOOL autoSlowdownBool;

  // allegiance panel outlets
  IBOutlet NSTableView *playerInfoTableView;
  IBOutlet NSButton *requestAllianceButton;
  IBOutlet NSButton *leaveAllianceButton;

  //! bolo tool matrix
  IBOutlet NSMatrix *builderToolMatrix;

  //! bolo tool data
  int builderToolInt;

  //! allegiance panel objects
  NSMutableArray *playerInfoArray;

  // messages panel outlets
  IBOutlet NSTextView *messagesTextView;
  IBOutlet NSTextField *messageTextField;
  IBOutlet NSMatrix *messageTargetMatrix;

  //! message panel data
  int messageTargetInt;

  // toolbar
  NSToolbar *boloToolbar;
  NSToolbarItem *builderToolItem;
  NSToolbarItem *tankCenterItem;
  NSToolbarItem *pillCenterItem;
  NSToolbarItem *zoomInItem;
  NSToolbarItem *zoomOutItem;

  //! zoom
  int zoomLevel;

  /*! UPnP port mapper */
  TCMPortMapper *portMapper;

  // bot
  NSLock *robotLock;
  GSRobot *robot;
}

// IBAction methods

// host game actions
- (IBAction)hostUPnPSwitch:(nullable id)sender;
- (IBAction)hostPort:(nullable id)sender;
- (IBAction)hostPasswordSwitch:(nullable id)sender;
- (IBAction)hostPassword:(nullable id)sender;
- (IBAction)hostTimeLimitSwitch:(nullable id)sender;
- (IBAction)hostTimeLimit:(nullable id)sender;
- (IBAction)hostHiddenMinesSwitch:(nullable id)sender;
- (IBAction)hostTrackerSwitch:(nullable id)sender;
- (IBAction)hostToggleBonjourBroadcast:(nullable id)sender;
@property (nonatomic) BOOL broadcastBonjour;

// domination controls
- (IBAction)hostDominationType:(nullable id)sender;
- (IBAction)hostDominationBaseControl:(nullable id)sender;

// join game actions
- (IBAction)joinPasswordSwitch:(nullable id)sender;
- (IBAction)joinPassword:(nullable id)sender;
- (IBAction)joinTrackerRefresh:(nullable id)sender;
- (IBAction)joinToggleBonjourListen:(nullable NSButton*)sender;

// shared actions for host and join
- (IBAction)tracker:(nullable id)sender;

// pref pane actions
- (IBAction)showPrefs:(nullable id)sender;
- (IBAction)prefPane:(nullable id)sender;
- (IBAction)prefPlayerName:(nullable id)sender;
- (IBAction)revertKeyConfig:(nullable id)sender;
- (IBAction)applyKeyConfig:(nullable id)sender;

// toolbar actions
- (IBAction)builderTool:(nullable id)sender;
- (IBAction)builderToolMenu:(nullable id)sender;
- (IBAction)tankCenter:(nullable id)sender;
- (IBAction)pillCenter:(nullable id)sender;
- (IBAction)zoomIn:(nullable id)sender;
- (IBAction)zoomOut:(nullable id)sender;

// menu actions
- (IBAction)closeGame:(nullable id)sender;
- (IBAction)newGame:(nullable id)sender;
- (IBAction)toggleJoin:(nullable id)sender;
- (IBAction)toggleMute:(nullable id)sender;
- (IBAction)gamePauseResumeMenu:(nullable id)sender;
- (IBAction)kickPlayer:(nullable id)sender;
- (IBAction)banPlayer:(nullable id)sender;
- (IBAction)unbanPlayer:(nullable id)sender;

// host actions
- (IBAction)hostChoose:(nullable id)sender;
- (IBAction)hostOK:(nullable id)sender;

// join actions
- (IBAction)joinPort:(nullable id)sender;
- (IBAction)joinOK:(nullable id)sender;

// join progress actions
- (IBAction)joinCancel:(nullable id)sender;

// game actions
- (IBAction)statusPanel:(nullable id)sender;
- (IBAction)allegiancePanel:(nullable id)sender;
- (IBAction)messagesPanel:(nullable id)sender;

// scroll view
- (IBAction)scrollUp:(nullable id)sender;
- (IBAction)scrollDown:(nullable id)sender;
- (IBAction)scrollLeft:(nullable id)sender;
- (IBAction)scrollRight:(nullable id)sender;

// allegiance panel actions
- (IBAction)requestAlliance:(nullable id)sender;
- (IBAction)leaveAlliance:(nullable id)sender;

// messages panel actions
- (IBAction)sendMessage:(nullable id)sender;
- (IBAction)messageTarget:(nullable id)sender;

// key event method
- (void)keyEvent:(BOOL)event forKey:(unsigned short)keyCode;

// mouse event method
- (void)mouseEvent:(GSPoint)point;

// accessor methods
@property (nonatomic, copy, nullable) NSURL * hostMap;
@property (nonatomic) BOOL hostUPnP;
@property (nonatomic) unsigned short hostPort;
@property (nonatomic) BOOL hasHostPassword;
@property (nonatomic, copy) NSString *hostPassword;
@property (nonatomic) BOOL hasHostTimeLimit;
@property (nonatomic, copy) NSString *hostTimeLimit;
@property (nonatomic) BOOL hostHiddenMines;
@property (nonatomic) BOOL hostTracker;
@property (nonatomic) int hostGameType;
@property (nonatomic) int hostDominationType;
@property (nonatomic, copy) NSString *hostDominationBaseControl;
@property (nonatomic, copy) NSString *joinAddress;
@property (nonatomic) unsigned short joinPort;
@property (nonatomic) BOOL joinPasswordEnabled;
@property (nonatomic, copy) NSString *joinPassword;
- (void)setJoinTrackerArray:(NSArray<NSDictionary<NSString*,id>*> *)aArray;
@property (nonatomic, copy) NSString *tracker;
@property (nonatomic, copy) NSToolbarItemIdentifier prefPaneIdentifier;
@property (nonatomic, copy) NSString *playerName;
- (void)setKeyConfigDict:(NSDictionary<NSString*,NSString*> *)aDict;
@property (nonatomic) BOOL autoSlowdown;
@property (nonatomic) BOOL showStatus;
@property (nonatomic) BOOL showAllegiance;
@property (nonatomic) BOOL showMessages;
@property (nonatomic) int builderTool;
@property (nonatomic) int messageTarget;
@property (getter=isMuted, nonatomic) BOOL mute;

- (void)requestConnectionToServer:(NSString*)servStr port:(unsigned short)port password:(nullable NSString*)pass;

@end

// bolo callbacksinitclient
void setplayerstatus(int player);
void setpillstatus(int pill);
void setbasestatus(int base);
void settankstatus(void);
void playsound(int sound);
void printmessage(int type, const char *text);
void joinprogress(int statuscode, float progress);
void trackerprogress(int statuscode);
void clientloopupdate(void);

NS_ASSUME_NONNULL_END
