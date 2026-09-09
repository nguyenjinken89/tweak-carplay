//
//  Common.h
//  CarPlayMaster
//
//  Định nghĩa các thông số, macro, và IPC notification cho toàn bộ tweak.
//

#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// Notification IPC names giữa SpringBoard, CarPlay.app và User Apps
#define CPM_APP_LAUNCH_NOTIFICATION      @"com.anthony.carplaymaster.launch"
#define CPM_ROTATION_NOTIFICATION        @"com.anthony.carplaymaster.rotation"
#define CPM_PREFS_CHANGED_NOTIFICATION   @"com.anthony.carplaymaster.prefschanged"
#define CPM_APP_LIST_REQUEST             @"com.anthony.carplaymaster.requestapps"
#define CPM_APP_LIST_RESPONSE            @"com.anthony.carplaymaster.responseapps"

// Đường dẫn file cấu hình preferences
#define CPM_PREFS_BUNDLE_ID              @"com.anthony.carplaymaster"
#define CPM_PREFS_FILE_PATH              @"/var/mobile/Library/Preferences/com.anthony.carplaymaster.plist"
#define CPM_ROOTLESS_PREFS_FILE_PATH     @"/var/jb/var/mobile/Library/Preferences/com.anthony.carplaymaster.plist"

// Kích thước chuẩn cho CarPlay Dock
#define CPM_CARPLAY_DOCK_WIDTH           64.0f

// Logging macro
#ifdef DEBUG
    #define CPMLog(fmt, ...) NSLog((@"[CarPlayMaster] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define CPMLog(fmt, ...) NSLog((@"[CarPlayMaster] " fmt), ##__VA_ARGS__)
#endif

// Objective-C runtime invocation helper macros
#define objcInvokeT(target, selString, returnType) (((returnType (*)(id, SEL))objc_msgSend)(target, NSSelectorFromString(selString)))
#define objcInvoke(target, selString) objcInvokeT(target, selString, id)
#define objcInvoke_1(target, selString, arg1) (((id (*)(id, SEL, id))objc_msgSend)(target, NSSelectorFromString(selString), (id)(arg1)))
#define objcInvoke_2(target, selString, arg1, arg2) (((id (*)(id, SEL, id, id))objc_msgSend)(target, NSSelectorFromString(selString), (id)(arg1), (id)(arg2)))
#define objcInvoke_3(target, selString, arg1, arg2, arg3) (((id (*)(id, SEL, id, id, id))objc_msgSend)(target, NSSelectorFromString(selString), (id)(arg1), (id)(arg2), (id)(arg3)))

// Property keys cho associated objects
static const char * const kCPMPropertyKey_LockAssertionIdentifiers = "kCPMPropertyKey_LockAssertionIdentifiers";
static const char * const kCPMPropertyKey_LiveCarPlayWindow = "kCPMPropertyKey_LiveCarPlayWindow";

// Helper lấy đường dẫn Rootless an toàn
static inline NSString *CPMGetPreferencesPath(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:@"/var/jb"]) {
        return CPM_ROOTLESS_PREFS_FILE_PATH;
    }
    return CPM_PREFS_FILE_PATH;
}
