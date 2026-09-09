//
//  CPMCarPlayWindow.m
//  CarPlayMaster
//

#import "CPMCarPlayWindow.h"
#import "../Preferences.h"

// Private declarations
@interface CADisplay : NSObject
+ (NSArray *)displays;
- (NSString *)uniqueId;
- (NSString *)name;
@end

@interface AVExternalDevice : NSObject
+ (id)currentCarPlayExternalDevice;
- (NSArray *)screenIDs;
@end

static id CPMGetCarPlayCADisplay(void) {
    id carplayAVDevice = objcInvoke(objc_getClass("AVExternalDevice"), @"currentCarPlayExternalDevice");
    if (!carplayAVDevice) {
        return nil;
    }

    NSArray *screenIDs = objcInvoke(carplayAVDevice, @"screenIDs");
    if (!screenIDs || screenIDs.count == 0) {
        return nil;
    }

    NSString *carplayScreenID = screenIDs[0];
    for (id display in objcInvoke(objc_getClass("CADisplay"), @"displays")) {
        if ([carplayScreenID isEqualToString:objcInvoke(display, @"uniqueId")]) {
            return display;
        }
    }
    return nil;
}

@implementation CPMCarPlayWindow {
    NSMutableArray *_observers;
    UITapGestureRecognizer *_screenTapRecognizer;
}

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier {
    self = [super init];
    if (self) {
        _bundleIdentifier = [bundleIdentifier copy];
        _observers = [[NSMutableArray alloc] init];
        _isFullscreen = NO;
        _orientation = UIInterfaceOrientationLandscapeRight;

        [[CPMPreferences sharedInstance] reloadPreferences];

        CPMLog(@"Initializing CarPlay window for app: %@", bundleIdentifier);

        id appController = objcInvoke(objc_getClass("SBApplicationController"), @"sharedInstance");
        self.application = objcInvoke_1(appController, @"applicationWithBundleIdentifier:", bundleIdentifier);

        if (!self.application) {
            CPMLog(@"Error: Failed to find SBApplication for %@", bundleIdentifier);
            return nil;
        }

        id carplayDisplay = CPMGetCarPlayCADisplay();
        if (carplayDisplay) {
            id displayConfig = objcInvoke_2([objc_getClass("FBSDisplayConfiguration") alloc], @"initWithCADisplay:isMainDisplay:", carplayDisplay, 0);
            self.rootWindow = objcInvoke_1([objc_getClass("UIRootSceneWindow") alloc], @"initWithDisplayConfiguration:", displayConfig);
            CPMLog(@"Created UIRootSceneWindow on CarPlay external display: %@", carplayDisplay);
        } else {
            // Fallback for debugging on main screen
            CPMLog(@"Warning: CarPlay display not detected, falling back to main screen");
            self.rootWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        }

        [self.rootWindow.layer setCornerRadius:12.0f];
        [self.rootWindow.layer setMasksToBounds:YES];

        [self setupBackground];
        [self setupDock];
        [self setupLiveAppView];

        CGRect windowBounds = self.rootWindow.bounds;
        CGFloat dockWidth = self.isFullscreen ? 0 : CPM_CARPLAY_DOCK_WIDTH;
        CGFloat dockXOrigin = [self shouldUseRightHandDock] ? 0 : dockWidth;

        self.appContainerView = [[UIView alloc] initWithFrame:CGRectMake(
            [self shouldUseRightHandDock] ? 0 : dockWidth,
            0,
            windowBounds.size.width - dockWidth,
            windowBounds.size.height
        )];
        self.appContainerView.backgroundColor = [UIColor clearColor];
        [self.rootWindow addSubview:self.appContainerView];

        if (self.appViewController) {
            UIView *appView = objcInvoke(self.appViewController, @"view");
            if (appView) {
                appView.frame = self.appContainerView.bounds;
                appView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [self.appContainerView addSubview:appView];
            }
        }

        self.rootWindow.alpha = 0.0f;
        self.rootWindow.hidden = NO;

        [UIView animateWithDuration:0.3 animations:^{
            self.rootWindow.alpha = 1.0f;
        }];

        // Unblank display for locked state rendering
        void (*orig_BKSDisplayServicesSetScreenBlanked)(int) = (void (*)(int))dlsym(RTLD_DEFAULT, "BKSDisplayServicesSetScreenBlanked");
        if (orig_BKSDisplayServicesSetScreenBlanked) {
            orig_BKSDisplayServicesSetScreenBlanked(0);
        }
    }
    return self;
}

- (BOOL)shouldUseRightHandDock {
    NSInteger pos = [CPMPreferences sharedInstance].dockPosition;
    if (pos == 1) return NO; // Left
    if (pos == 2) return YES; // Right
    // Auto based on car preference
    return NO;
}

- (void)setupBackground {
    CGRect frame = self.rootWindow.bounds;
    BOOL isAMOLED = [CPMPreferences sharedInstance].amoledBlackWallpaper;

    if (isAMOLED) {
        UIView *blackBg = [[UIView alloc] initWithFrame:frame];
        blackBg.backgroundColor = [UIColor blackColor];
        blackBg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.rootWindow addSubview:blackBg];
    } else {
        UIImageView *wallpaperView = [[UIImageView alloc] initWithFrame:frame];
        wallpaperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        Class crsPrefClass = objc_getClass("CRSUIWallpaperPreferences");
        if (crsPrefClass) {
            id defaultWallpaper = objcInvoke(crsPrefClass, @"defaultWallpaper");
            if (defaultWallpaper) {
                UIImage *wallpaperImg = objcInvoke_1(defaultWallpaper, @"wallpaperImageCompatibleWithTraitCollection:", nil);
                [wallpaperView setImage:wallpaperImg];
            }
        }

        if (!wallpaperView.image) {
            wallpaperView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:1.0];
        }

        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
        blurView.frame = frame;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [wallpaperView addSubview:blurView];

        [self.rootWindow addSubview:wallpaperView];
    }
}

- (void)setupDock {
    if (self.dockView) {
        [self.dockView removeFromSuperview];
    }

    if (self.isFullscreen) {
        return;
    }

    CGRect bounds = self.rootWindow.bounds;
    BOOL rightDock = [self shouldUseRightHandDock];
    CGFloat xPos = rightDock ? (bounds.size.width - CPM_CARPLAY_DOCK_WIDTH) : 0;

    self.dockView = [[UIView alloc] initWithFrame:CGRectMake(xPos, 0, CPM_CARPLAY_DOCK_WIDTH, bounds.size.height)];
    self.dockView.autoresizingMask = rightDock ? (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight) : (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight);

    // Glassmorphism blur
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurView.frame = self.dockView.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.dockView addSubview:blurView];

    // Home / Dismiss Button
    CGFloat btnSize = 36.0f;
    CGFloat padding = 14.0f;

    UIButton *homeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    homeBtn.frame = CGRectMake((CPM_CARPLAY_DOCK_WIDTH - btnSize) / 2.0f, bounds.size.height - btnSize - padding, btnSize, btnSize);
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold];
    [homeBtn setImage:[UIImage systemImageNamed:@"circle.grid.2x2.fill" withConfiguration:config] forState:UIControlStateNormal];
    homeBtn.tintColor = [UIColor whiteColor];
    [homeBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.dockView addSubview:homeBtn];

    // Fullscreen Toggle Button
    UIButton *fullscreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    fullscreenBtn.frame = CGRectMake((CPM_CARPLAY_DOCK_WIDTH - btnSize) / 2.0f, padding, btnSize, btnSize);
    [fullscreenBtn setImage:[UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right" withConfiguration:config] forState:UIControlStateNormal];
    fullscreenBtn.tintColor = [UIColor whiteColor];
    [fullscreenBtn addTarget:self action:@selector(toggleFullscreen) forControlEvents:UIControlEventTouchUpInside];
    [self.dockView addSubview:fullscreenBtn];

    // Rotate Button
    UIButton *rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rotateBtn.frame = CGRectMake((CPM_CARPLAY_DOCK_WIDTH - btnSize) / 2.0f, CGRectGetMaxY(fullscreenBtn.frame) + padding, btnSize, btnSize);
    [rotateBtn setImage:[UIImage systemImageNamed:@"rotate.right.fill" withConfiguration:config] forState:UIControlStateNormal];
    rotateBtn.tintColor = [UIColor whiteColor];
    [rotateBtn addTarget:self action:@selector(handleRotate) forControlEvents:UIControlEventTouchUpInside];
    [self.dockView addSubview:rotateBtn];

    // Close app button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake((CPM_CARPLAY_DOCK_WIDTH - btnSize) / 2.0f, CGRectGetMaxY(rotateBtn.frame) + padding, btnSize, btnSize);
    [closeBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:config] forState:UIControlStateNormal];
    closeBtn.tintColor = [UIColor colorWithRed:1.0 green:0.25 blue:0.25 alpha:0.9];
    [closeBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.dockView addSubview:closeBtn];

    [self.rootWindow addSubview:self.dockView];
}

- (void)setupLiveAppView {
    @try {
        id sceneManagerCoord = objcInvoke(objc_getClass("SBSceneManagerCoordinator"), @"mainDisplaySceneManager");
        if (!sceneManagerCoord) return;

        id mainScreenIdentity = objcInvoke(sceneManagerCoord, @"displayIdentity");
        id sceneIdentity = objcInvoke_2(sceneManagerCoord, @"_sceneIdentityForApplication:createPrimaryIfRequired:", self.application, 1);

        id sceneHandleRequest = objcInvoke_3(objc_getClass("SBApplicationSceneHandleRequest"), 
                                            @"defaultRequestForApplication:sceneIdentity:displayIdentity:", 
                                            self.application, sceneIdentity, mainScreenIdentity);

        id sceneHandle = objcInvoke_1(sceneManagerCoord, @"fetchOrCreateApplicationSceneHandleForRequest:", sceneHandleRequest);
        id appSceneEntity = objcInvoke_1([objc_getClass("SBDeviceApplicationSceneEntity") alloc], @"initWithApplicationSceneHandle:", sceneHandle);

        self.appViewController = objcInvoke_2([objc_getClass("SBAppViewController") alloc], 
                                            @"initWithIdentifier:andApplicationSceneEntity:", 
                                            self.bundleIdentifier, appSceneEntity);

        if (self.appViewController) {
            objcInvoke_1(self.appViewController, @"setIgnoresOcclusions:", 0);

            // Notify user app to rotate
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSDistributedNotificationCenter defaultCenter] postNotificationName:CPM_ROTATION_NOTIFICATION 
                                                                               object:self.bundleIdentifier 
                                                                             userInfo:@{@"orientation": @(self.orientation)}];
            });
        }
    }
    @catch (NSException *ex) {
        CPMLog(@"Exception setting up live app view: %@", ex);
    }
}

- (void)toggleFullscreen {
    self.isFullscreen = !self.isFullscreen;
    [UIView animateWithDuration:0.25 animations:^{
        CGRect bounds = self.rootWindow.bounds;
        if (self.isFullscreen) {
            self.dockView.alpha = 0.0f;
            self.appContainerView.frame = bounds;
        } else {
            self.dockView.alpha = 1.0f;
            CGFloat dockWidth = CPM_CARPLAY_DOCK_WIDTH;
            BOOL rightDock = [self shouldUseRightHandDock];
            self.appContainerView.frame = CGRectMake(rightDock ? 0 : dockWidth, 0, bounds.size.width - dockWidth, bounds.size.height);
        }
    }];
}

- (void)handleRotate {
    if (self.orientation == UIInterfaceOrientationLandscapeRight) {
        self.orientation = UIInterfaceOrientationLandscapeLeft;
    } else if (self.orientation == UIInterfaceOrientationLandscapeLeft) {
        self.orientation = UIInterfaceOrientationPortrait;
    } else {
        self.orientation = UIInterfaceOrientationLandscapeRight;
    }

    CPMLog(@"Rotating app to orientation: %ld", (long)self.orientation);
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:CPM_ROTATION_NOTIFICATION 
                                                                   object:self.bundleIdentifier 
                                                                 userInfo:@{@"orientation": @(self.orientation)}];
}

- (void)dismiss {
    CPMLog(@"Dismissing CarPlay app window: %@", self.bundleIdentifier);
    [UIView animateWithDuration:0.2 animations:^{
        self.rootWindow.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.rootWindow.hidden = YES;
        [self.rootWindow removeFromSuperview];
        self.rootWindow = nil;
        self.dockView = nil;
        self.appContainerView = nil;
        self.appViewController = nil;
    }];
}

@end
