//
//  Preferences.m
//  CarPlayMaster
//

#import "Preferences.h"
#import "Common.h"

@implementation CPMPreferences

+ (instancetype)sharedInstance {
    static CPMPreferences *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reloadPreferences];
    }
    return self;
}

- (void)reloadPreferences {
    NSString *plistPath = CPMGetPreferencesPath();
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    // Defaults
    self.enabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : YES;
    self.bypassDrivingLimits = prefs[@"bypassDrivingLimits"] ? [prefs[@"bypassDrivingLimits"] boolValue] : YES;
    self.enableAllApps = prefs[@"enableAllApps"] ? [prefs[@"enableAllApps"] boolValue] : YES;
    self.excludedApps = prefs[@"excludedApps"] ?: @[];
    self.selectedApps = prefs[@"selectedApps"] ?: @[];

    // Grid Layout defaults (5 columns, 2 rows)
    self.iconColumns = prefs[@"iconColumns"] ? [prefs[@"iconColumns"] integerValue] : 5;
    if (self.iconColumns < 3) self.iconColumns = 3;
    if (self.iconColumns > 8) self.iconColumns = 8;

    self.iconRows = prefs[@"iconRows"] ? [prefs[@"iconRows"] integerValue] : 2;
    if (self.iconRows < 1) self.iconRows = 1;
    if (self.iconRows > 4) self.iconRows = 4;

    self.iconScale = prefs[@"iconScale"] ? [prefs[@"iconScale"] floatValue] : 0.85f;
    self.hideIconLabels = prefs[@"hideIconLabels"] ? [prefs[@"hideIconLabels"] boolValue] : NO;
    self.dockPosition = prefs[@"dockPosition"] ? [prefs[@"dockPosition"] integerValue] : 0;

    self.preventAutoLock = prefs[@"preventAutoLock"] ? [prefs[@"preventAutoLock"] boolValue] : YES;
    self.enableBatteryPercentage = prefs[@"enableBatteryPercentage"] ? [prefs[@"enableBatteryPercentage"] boolValue] : YES;
    self.enableThermalAlert = prefs[@"enableThermalAlert"] ? [prefs[@"enableThermalAlert"] boolValue] : YES;
    self.amoledBlackWallpaper = prefs[@"amoledBlackWallpaper"] ? [prefs[@"amoledBlackWallpaper"] boolValue] : NO;
    self.privacyHideNotifications = prefs[@"privacyHideNotifications"] ? [prefs[@"privacyHideNotifications"] boolValue] : NO;

    CPMLog(@"Preferences reloaded: enabled=%d, bypassLimits=%d, cols=%ld, rows=%ld", 
           self.enabled, self.bypassDrivingLimits, (long)self.iconColumns, (long)self.iconRows);
}

- (BOOL)isAppAllowedOnCarPlay:(NSString *)bundleIdentifier {
    if (!self.enabled) return NO;
    if (!bundleIdentifier || bundleIdentifier.length == 0) return NO;

    // Skip apple system daemons / internal apps
    if ([bundleIdentifier hasPrefix:@"com.apple.springboard"] ||
        [bundleIdentifier hasPrefix:@"com.apple.CarPlayApp"] ||
        [bundleIdentifier hasPrefix:@"com.apple.CarPlayTemplateUIHost"]) {
        return YES;
    }

    if (self.excludedApps && [self.excludedApps containsObject:bundleIdentifier]) {
        return NO;
    }

    if (self.enableAllApps) {
        return YES;
    }

    if (self.selectedApps && [self.selectedApps containsObject:bundleIdentifier]) {
        return YES;
    }

    return NO;
}

@end
