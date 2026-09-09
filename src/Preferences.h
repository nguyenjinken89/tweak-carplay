//
//  Preferences.h
//  CarPlayMaster
//
//  Quản lý cấu hình toàn diện cho CarPlayMaster
//

#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CPMPreferences : NSObject

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL bypassDrivingLimits;
@property (nonatomic, assign) BOOL enableAllApps;
@property (nonatomic, strong) NSArray<NSString *> *excludedApps;
@property (nonatomic, strong) NSArray<NSString *> *selectedApps;
@property (nonatomic, assign) NSInteger iconColumns;
@property (nonatomic, assign) NSInteger iconRows;
@property (nonatomic, assign) CGFloat iconScale;
@property (nonatomic, assign) BOOL hideIconLabels;
@property (nonatomic, assign) NSInteger dockPosition; // 0 = Auto, 1 = Left, 2 = Right
@property (nonatomic, assign) BOOL preventAutoLock;
@property (nonatomic, assign) BOOL enableBatteryPercentage;
@property (nonatomic, assign) BOOL enableThermalAlert;
@property (nonatomic, assign) BOOL amoledBlackWallpaper;
@property (nonatomic, assign) BOOL privacyHideNotifications;

+ (instancetype)sharedInstance;
- (void)reloadPreferences;
- (BOOL)isAppAllowedOnCarPlay:(NSString *)bundleIdentifier;

@end
