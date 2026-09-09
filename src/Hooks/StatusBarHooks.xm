//
//  StatusBarHooks.xm
//  CarPlayMaster
//
//  Tối ưu riêng cho iPhone 6s Plus (chip A9) và các dòng máy khác:
//  Hiển thị % Pin thật, trạng thái sạc và nhiệt độ máy/cảnh báo quá nhiệt
//  trực tiếp trên thanh trạng thái (Status Bar) của CarPlay
//

#import "../Common.h"
#import "../Preferences.h"

static NSString *CPMGetBatteryAndThermalString(void) {
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    float level = [UIDevice currentDevice].batteryLevel;
    int batteryPercent = (level < 0.0f) ? 100 : (int)(level * 100.0f);

    UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
    BOOL isCharging = (state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull);

    // Giám sát trạng thái nhiệt độ chip Apple A9 / iOS Thermal State
    NSProcessInfoThermalState thermalState = [NSProcessInfo processInfo].thermalState;
    NSString *thermalIcon = @"🟢";
    if (thermalState == NSProcessInfoThermalStateFair) {
        thermalIcon = @"🟡";
    } else if (thermalState == NSProcessInfoThermalStateSerious) {
        thermalIcon = @"🟠 Nóng!";
    } else if (thermalState == NSProcessInfoThermalStateCritical) {
        thermalIcon = @"🔴 Quá nhiệt!";
    }

    NSString *batteryStr = [NSString stringWithFormat:@"%d%%%@", batteryPercent, isCharging ? @"⚡" : @""];
    return [NSString stringWithFormat:@"%@ %@", batteryStr, thermalIcon];
}

%group STATUSBAR_HOOKS

// Hook nhãn thời gian hoặc trạng thái trên thanh Status Bar của CarPlay để bổ sung thông tin pin & nhiệt
%hook SBStarkStatusBarViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && (prefs.enableBatteryPercentage || prefs.enableThermalAlert)) {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    }
}

%end

// Hook vào định dạng chuỗi hiển thị trạng thái của CarPlay
%hook CRSUIStatusBarStyleAssertion

- (id)init {
    id orig = %orig;
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    return orig;
}

%end

// Hook cập nhật nhãn thời gian/thanh trạng thái
%hook SBStarkTimeControl

- (id)_formattedTimeString {
    id origTime = %orig;
    CPMPreferences *prefs = [CPMPreferences sharedInstance];
    if (prefs.enabled && prefs.enableBatteryPercentage) {
        NSString *extraInfo = CPMGetBatteryAndThermalString();
        return [NSString stringWithFormat:@"%@  [%@]", origTime, extraInfo];
    }
    return origTime;
}

%end

%end

%ctor {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString:@"com.apple.CarPlayApp"] || 
        [bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        CPMLog(@"Initializing StatusBar battery & thermal hooks");
        %init(STATUSBAR_HOOKS);
    }
}
