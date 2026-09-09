//
//  AppRotationHooks.xm
//  CarPlayMaster
//
//  Inject vào ứng dụng người dùng (User Applications) để:
//  Ép xoay ngang (Force Landscape) cho các app vốn chỉ hỗ trợ màn hình dọc
//  giúp ứng dụng hiển thị vừa vặn và đẹp mắt trên màn hình xe hơi
//

#import "../Common.h"

static int gTargetOrientation = -1;

%group USER_APPS

%hook UIApplication

- (id)init {
    id orig = %orig;

    // Đăng ký nhận thông báo đổi hướng xoay từ CarPlayMaster
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleID) {
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self 
                                                            selector:NSSelectorFromString(@"cpm_handleRotationRequest:") 
                                                                name:CPM_ROTATION_NOTIFICATION 
                                                              object:bundleID];
    }
    return orig;
}

%new
- (void)cpm_handleRotationRequest:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    if (userInfo && userInfo[@"orientation"]) {
        gTargetOrientation = [userInfo[@"orientation"] intValue];
        CPMLog(@"User app requested rotation to: %d", gTargetOrientation);

        UIWindow *keyWin = [UIApplication sharedApplication].keyWindow;
        if (keyWin) {
            void (*setOrient)(id, SEL, int, float, int) = (void (*)(id, SEL, int, float, int))objc_msgSend;
            setOrient(keyWin, NSSelectorFromString(@"_setRotatableViewOrientation:duration:force:"), gTargetOrientation, 0.2f, 1);
        }
    }
}

%end

// Ép cửa sổ ứng dụng xoay theo hướng được chỉ định
%hook UIWindow

- (void)_setRotatableViewOrientation:(int)orientation duration:(float)duration force:(int)force {
    if (gTargetOrientation > 0) {
        %orig(gTargetOrientation, duration, 1);
        return;
    }
    %orig;
}

%end

// Cho phép tất cả các hướng xoay để tránh bị chặn bởi UIViewController
%hook UIViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (gTargetOrientation > 0) {
        return UIInterfaceOrientationMaskAll;
    }
    return %orig;
}

- (BOOL)shouldAutorotate {
    if (gTargetOrientation > 0) {
        return YES;
    }
    return %orig;
}

%end

%end

%ctor {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];

    // Chỉ inject vào ứng dụng người dùng (User apps) hoặc ứng dụng jailbreak, bỏ qua tiến trình Apple
    if ([bundlePath containsString:@".app"] && 
        ![bundleIdentifier isEqualToString:@"com.apple.springboard"] && 
        ![bundleIdentifier isEqualToString:@"com.apple.CarPlayApp"]) {
        CPMLog(@"Initializing AppRotationHooks for user app: %@", bundleIdentifier);
        %init(USER_APPS);
    }
}
