//
//  CarPlayAppHooks.xm
//  CarPlayMaster
//
//  Hook vào tiến trình CarPlay.app để:
//  1. Ép tất cả ứng dụng người dùng chọn xuất hiện trên màn hình CarPlay
//  2. Tùy chỉnh số cột/dòng icon (4x2, 5x2, 6x2...), kích thước icon
//  3. Điều hướng mở ứng dụng sang SpringBoard qua IPC
//

#import "../Common.h"
#import "../Preferences.h"

struct SBIconImageInfo {
    struct CGSize size;
    double scale;
    double continuousCornerRadius;
};

%group CARPLAY_APP

// Inject declarations vào AppLibrary của CarPlay
static void CPMAddDeclarationsToAppLibrary(id appLibrary) {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    [prefs reloadPreferences];

    if (!prefs.enabled) return;

    for (id appInfo in objcInvoke(appLibrary, @"allInstalledApplications")) {
        if (getIvar(appInfo, @"_carPlayDeclaration") == nil) {
            NSString *bundleID = objcInvoke(appInfo, @"bundleIdentifier");

            // Kiểm tra app có được phép lên CarPlay hay không
            if (![prefs isAppAllowedOnCarPlay:bundleID]) {
                continue;
            }

            // Tạo declaration giả để CarPlay nhận diện app hợp lệ
            Class declClass = objc_getClass("CRCarPlayAppDeclaration");
            if (declClass) {
                id declaration = [[declClass alloc] init];
                objcInvoke_1(declaration, @"setSupportsTemplates:", 0);
                objcInvoke_1(declaration, @"setSupportsMaps:", 1);
                objcInvoke_1(declaration, @"setBundleIdentifier:", bundleID);
                objcInvoke_1(declaration, @"setBundlePath:", objcInvoke(appInfo, @"bundleURL"));
                setIvar(appInfo, @"_carPlayDeclaration", declaration);

                // Gắn tag đánh dấu do CarPlayMaster mở khóa
                NSArray *tags = @[@"CarPlayMaster"];
                if (objcInvoke(appInfo, @"tags")) {
                    tags = [tags arrayByAddingObjectsFromArray:objcInvoke(appInfo, @"tags")];
                }
                setIvar(appInfo, @"_tags", tags);
            }
        }
    }
}

%hook CARApplication

+ (id)_newApplicationLibrary {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    [prefs reloadPreferences];

    if (!prefs.enabled) {
        return %orig;
    }

    id allAppsConfig = [[objc_getClass("FBSApplicationLibraryConfiguration") alloc] init];
    objcInvoke_1(allAppsConfig, @"setApplicationInfoClass:", objc_getClass("CARApplicationInfo"));
    objcInvoke_1(allAppsConfig, @"setApplicationPlaceholderClass:", objc_getClass("FBSApplicationPlaceholder"));
    objcInvoke_1(allAppsConfig, @"setAllowConcurrentLoading:", 1);
    objcInvoke_1(allAppsConfig, @"setInstalledApplicationFilter:", ^BOOL(id appProxy, NSSet *arg2) {
        NSArray *appTags = objcInvoke(appProxy, @"appTags");
        if ([appTags containsObject:@"hidden"]) {
            return NO;
        }
        return YES;
    });

    id allAppsLibrary = objcInvoke_1([objc_getClass("FBSApplicationLibrary") alloc], @"initWithConfiguration:", allAppsConfig);
    CPMAddDeclarationsToAppLibrary(allAppsLibrary);

    // Bổ sung các dịch vụ hệ thống cần thiết của CarPlay
    NSArray *systemIdentList = @[
        @"com.apple.CarPlayTemplateUIHost",
        @"com.apple.MusicUIService",
        @"com.apple.springboard",
        @"com.apple.InCallService",
        @"com.apple.CarPlaySettings",
        @"com.apple.CarPlayApp"
    ];

    for (NSString *ident in systemIdentList) {
        id appProxy = objcInvoke_1(objc_getClass("LSApplicationProxy"), @"applicationProxyForIdentifier:", ident);
        id appState = objcInvoke(appProxy, @"appState");
        if (objcInvokeT(appState, @"isValid", int) == 1) {
            objcInvoke_2(allAppsLibrary, @"addApplicationProxy:withOverrideURL:", appProxy, 0);
        }
    }

    return allAppsLibrary;
}

%end

// Xử lý khi người dùng chạm vào icon app trên màn hình xe
%hook CARApplicationLaunchInfo

+ (id)launchInfoForApplication:(id)application withActivationSettings:(id)settings {
    NSArray *tags = objcInvoke(application, @"tags");
    if ([tags containsObject:@"CarPlayMaster"]) {
        NSString *bundleID = objcInvoke(application, @"bundleIdentifier");
        CPMLog(@"Launching forced CarPlay app via IPC: %@", bundleID);

        // Gửi thông báo IPC sang SpringBoard để host cửa sổ app
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:CPM_APP_LAUNCH_NOTIFICATION 
                                                                       object:nil 
                                                                     userInfo:@{@"identifier": bundleID}];

        // Thêm app vào lịch sử gần đây của Dock CarPlay
        id sharedApp = [UIApplication sharedApplication];
        id appHistory = objcInvoke(sharedApp, @"_currentAppHistory");
        if (appHistory) {
            objcInvoke_1(appHistory, @"setApplicationWasRecentLaunched:", application);
        }
        return nil;
    }
    return %orig;
}

%end

// Tùy biến lưới hiển thị icon trên màn hình xe (Columns, Rows, Size)
%hook SBIconListGridLayoutConfiguration

- (int)numberOfPortraitColumns {
    int originalCols = %orig;
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.iconColumns > 0) {
        return (int)prefs.iconColumns;
    }
    return originalCols;
}

- (int)numberOfPortraitRows {
    int originalRows = %orig;
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.iconRows > 0) {
        return (int)prefs.iconRows;
    }
    return originalRows;
}

- (struct SBIconImageInfo)iconImageInfoForGridSizeClass:(unsigned long long)arg1 {
    struct SBIconImageInfo info = %orig;
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled) {
        CGFloat scale = prefs.iconScale > 0 ? prefs.iconScale : 0.85f;
        CGFloat newDim = 60.0f * scale;
        info.size = CGSizeMake(newDim, newDim);
    }
    return info;
}

%end

// Tùy chọn ẩn nhãn tên ứng dụng (Hide Icon Labels)
%hook SBIconLabelImageParameters

- (BOOL)colorsEquateToColor:(id)arg1 {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.hideIconLabels) {
        return YES;
    }
    return %orig;
}

%end

%end

%ctor {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString:@"com.apple.CarPlayApp"]) {
        CPMLog(@"Initializing CarPlayMaster hooks in CarPlayApp");
        %init(CARPLAY_APP);
    }
}
