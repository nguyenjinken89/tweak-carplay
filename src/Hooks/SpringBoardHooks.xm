//
//  SpringBoardHooks.xm
//  CarPlayMaster
//
//  Hook vào SpringBoard để:
//  1. Nhận lệnh mở app từ CarPlayApp qua IPC và khởi tạo CPMCarPlayWindow
//  2. Ngăn iOS treo/kill ứng dụng khi khóa màn hình (Keep-Alive under Lock)
//  3. Tùy chọn chống tự động khóa màn hình (Prevent Auto-Lock)
//  4. Bảo vệ riêng tư: Ẩn xem trước tin nhắn thông báo trên màn hình xe
//  5. Cung cấp danh sách app đã cài đặt cho mục Cài đặt (Preferences)
//

#import "../Common.h"
#import "../Preferences.h"
#import "../Window/CPMCarPlayWindow.h"

static CPMCarPlayWindow *activeCarPlayWindow = nil;
static BOOL isCarPlayConnected = NO;

%group SPRINGBOARD

%hook SBSuspendedUnderLockManager

// Ngăn hệ thống đóng băng app khi iPhone bị khóa màn hình
- (BOOL)_shouldBeBackgroundUnderLockForScene:(id)scene withSettings:(id)settings {
    BOOL shouldBackground = %orig;
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && activeCarPlayWindow != nil) {
        NSString *sceneBundleID = objcInvoke(objcInvoke(objcInvoke(scene, @"client"), @"process"), @"bundleIdentifier");
        if ([sceneBundleID isEqualToString:activeCarPlayWindow.bundleIdentifier]) {
            CPMLog(@"Preventing background under lock for CarPlay app: %@", sceneBundleID);
            return NO;
        }
    }
    return shouldBackground;
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    CPMLog(@"SpringBoard finished launching, registering CarPlayMaster observers");

    // Lắng nghe yêu cầu mở app từ CarPlayApp
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:CPM_APP_LAUNCH_NOTIFICATION 
                                                                 object:nil 
                                                                  queue:[NSOperationQueue mainQueue] 
                                                             usingBlock:^(NSNotification *note) {
        NSString *bundleID = note.userInfo[@"identifier"];
        if (!bundleID) return;

        CPMLog(@"Received launch request for: %@", bundleID);

        // Đóng cửa sổ cũ nếu đang mở
        if (activeCarPlayWindow != nil) {
            [activeCarPlayWindow dismiss];
            activeCarPlayWindow = nil;
        }

        // Mở cửa sổ mới trên màn hình CarPlay
        activeCarPlayWindow = [[CPMCarPlayWindow alloc] initWithBundleIdentifier:bundleID];
    }];

    // Lắng nghe thay đổi cấu hình từ Cài đặt
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:CPM_PREFS_CHANGED_NOTIFICATION 
                                                                 object:nil 
                                                                  queue:[NSOperationQueue mainQueue] 
                                                             usingBlock:^(NSNotification *note) {
        [[CPMPreferences sharedInstance] reloadPreferences];
    }];

    // Lắng nghe trạng thái kết nối CarPlay (khi rút dây/ngắt kết nối thì dọn dẹp window)
    [[NSNotificationCenter defaultCenter] addObserverForName:@"CarPlayIsConnectedDidChange" 
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue] 
                                                  usingBlock:^(NSNotification *note) {
        if (activeCarPlayWindow != nil) {
            [activeCarPlayWindow dismiss];
            activeCarPlayWindow = nil;
        }
    }];

    // Phục vụ danh sách ứng dụng đã cài đặt cho giao diện Cài đặt (Preferences)
    NSOperationQueue *appQueryQueue = [[NSOperationQueue alloc] init];
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:CPM_APP_LIST_REQUEST 
                                                                 object:nil 
                                                                  queue:appQueryQueue 
                                                             usingBlock:^(NSNotification *note) {
        id appController = objcInvoke(objc_getClass("SBApplicationController"), @"sharedInstance");
        NSMutableArray *appList = [[NSMutableArray alloc] init];

        for (id app in objcInvoke(appController, @"allInstalledApplications")) {
            NSString *bundleID = objcInvoke(app, @"bundleIdentifier");
            NSString *displayName = objcInvoke(app, @"displayName") ?: bundleID;

            // Bỏ qua các app hệ thống cơ bản không cần thiết
            if ([bundleID hasPrefix:@"com.apple."] && ![bundleID containsString:@"Maps"] && ![bundleID containsString:@"Music"]) {
                continue;
            }

            [appList addObject:@{
                @"bundleIdentifier": bundleID,
                @"displayName": displayName
            }];
        }

        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:CPM_APP_LIST_RESPONSE 
                                                                       object:nil 
                                                                     userInfo:@{@"apps": appList}];
    }];
}

%end

// Chống tự động tắt màn hình khi đang kết nối CarPlay
%hook SBIdleTimerGlobalCoordinator

- (void)resetIdleTimer {
    %orig;
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.preventAutoLock && activeCarPlayWindow != nil) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
}

%end

// Bảo vệ riêng tư: Ẩn xem trước thông báo nhạy cảm trên màn hình xe
%hook NCNotificationContent

- (NSString *)message {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.privacyHideNotifications && activeCarPlayWindow != nil) {
        return @"[Nội dung thông báo đã được ẩn vì bảo mật]";
    }
    return %orig;
}

%end

%end

%ctor {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        CPMLog(@"Initializing CarPlayMaster hooks in SpringBoard");
        %init(SPRINGBOARD);
    }
}
