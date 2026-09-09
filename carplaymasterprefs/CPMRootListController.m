//
//  CPMRootListController.m
//  CarPlayMasterPrefs
//

#import "CPMRootListController.h"
#import <spawn.h>
#import "../src/Common.h"

extern char **environ;

@implementation CPMRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];

    // Phát thông báo thay đổi cấu hình qua IPC
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:CPM_PREFS_CHANGED_NOTIFICATION 
                                                                   object:nil 
                                                                 userInfo:nil];
}

- (void)respring {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Khởi động lại CarPlay" 
                                                                   message:@"Thao tác này sẽ tải lại SpringBoard và CarPlay để áp dụng các thay đổi cài đặt mới nhất." 
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Khởi động ngay" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        pid_t pid;
        // Kiểm tra lệnh sbreload của rootless
        const char *sbreloadPaths[] = {
            "/var/jb/usr/bin/sbreload",
            "/usr/bin/sbreload",
            "/var/jb/usr/bin/killall",
            "/usr/bin/killall"
        };

        const char *targetCmd = NULL;
        for (int i = 0; i < 4; i++) {
            if (access(sbreloadPaths[i], X_OK) == 0) {
                targetCmd = sbreloadPaths[i];
                break;
            }
        }

        if (targetCmd && strstr(targetCmd, "sbreload")) {
            const char *argv[] = { targetCmd, NULL };
            posix_spawn(&pid, targetCmd, NULL, NULL, (char *const *)argv, environ);
        } else {
            // Fallback kill SpringBoard & CarPlay
            const char *killCmd = targetCmd ?: "/usr/bin/killall";
            const char *argv1[] = { killCmd, "-9", "SpringBoard", NULL };
            posix_spawn(&pid, killCmd, NULL, NULL, (char *const *)argv1, environ);

            const char *argv2[] = { killCmd, "-9", "CarPlay", NULL };
            posix_spawn(&pid, killCmd, NULL, NULL, (char *const *)argv2, environ);
        }
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetToDefaults {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Khôi phục mặc định" 
                                                                   message:@"Bạn có chắc chắn muốn đặt lại tất cả cài đặt về ban đầu?" 
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"Đặt lại" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSString *prefsPath = CPMGetPreferencesPath();
        [[NSFileManager defaultManager] removeItemAtPath:prefsPath error:nil];

        // Thông báo cập nhật
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:CPM_PREFS_CHANGED_NOTIFICATION 
                                                                       object:nil 
                                                                     userInfo:nil];

        [self reloadSpecifiers];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
