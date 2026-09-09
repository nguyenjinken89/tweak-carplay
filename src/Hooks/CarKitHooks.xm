//
//  CarKitHooks.xm
//  CarPlayMaster
//
//  Mở khóa hoàn toàn các giới hạn an toàn của Apple khi xe đang di chuyển:
//  1. Cho phép gõ bàn phím khi đang lái xe (Bypass Keyboard Speed Lock)
//  2. Bỏ giới hạn cuộn danh sách (Mặc định Apple chỉ cho cuộn tối đa 12 dòng)
//  3. Mở khóa toàn bộ tương tác cảm ứng (Touch Delivery & Interface Limitations)
//

#import "../Common.h"
#import "../Preferences.h"

%group CARKIT_HOOKS

// Hook cấu hình phiên làm việc CarPlay
%hook CARSessionConfiguration

- (BOOL)isLimitUserInterfaces {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.bypassDrivingLimits) {
        return NO;
    }
    return %orig;
}

- (BOOL)limitUserInterfaces {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.bypassDrivingLimits) {
        return NO;
    }
    return %orig;
}

- (NSUInteger)limitUserInterfacesMask {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.bypassDrivingLimits) {
        return 0;
    }
    return %orig;
}

- (BOOL)isTouchDeliveryRestricted {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.bypassDrivingLimits) {
        return NO;
    }
    return %orig;
}

- (BOOL)touchDeliveryRestricted {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.bypassDrivingLimits) {
        return NO;
    }
    return %orig;
}

%end

%hook CARSession

- (BOOL)isLimitUserInterfaces {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.bypassDrivingLimits) {
        return NO;
    }
    return %orig;
}

- (BOOL)limitUserInterfaces {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.bypassDrivingLimits) {
        return NO;
    }
    return %orig;
}

%end

// Hook bộ giám sát chính sách phương tiện di chuyển
%hook CRVehiclePolicyMonitor

- (BOOL)isVehicleMoving {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.bypassDrivingLimits) {
        return NO;
    }
    return %orig;
}

- (BOOL)drivingFilterActive {
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.bypassDrivingLimits) {
        return NO;
    }
    return %orig;
}

%end

%end

%ctor {
    CPMLog(@"Initializing CarKit driving limitation bypass hooks");
    %init(CARKIT_HOOKS);
}
