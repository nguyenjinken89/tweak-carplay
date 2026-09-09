//
//  CPMCarPlayWindow.h
//  CarPlayMaster
//
//  Quản lý cửa sổ và hiển thị ứng dụng trực tiếp trên màn hình CarPlay của xe
//

#pragma once

#import <UIKit/UIKit.h>
#import "../Common.h"

@interface CPMCarPlayWindow : NSObject

@property (nonatomic, strong) UIWindow *rootWindow;
@property (nonatomic, strong) UIView *dockView;
@property (nonatomic, strong) UIView *appContainerView;
@property (nonatomic, strong) UIImageView *launchImageView;
@property (nonatomic, strong) id appViewController;
@property (nonatomic, strong) id application;
@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) BOOL isFullscreen;

- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier;
- (void)dismiss;
- (void)toggleFullscreen;
- (void)handleRotate;

@end
