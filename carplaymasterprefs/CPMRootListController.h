//
//  CPMRootListController.h
//  CarPlayMasterPrefs
//

#import <UIKit/UIKit.h>

@interface PSSpecifier : NSObject
@property (nonatomic, strong) id target;
@property (nonatomic, strong) NSString *name;
@end

@interface PSListController : UIViewController
- (id)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
- (void)reloadSpecifiers;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
- (id)readPreferenceValue:(PSSpecifier *)specifier;
@end

@interface CPMRootListController : PSListController

- (void)respring;
- (void)resetToDefaults;

@end
