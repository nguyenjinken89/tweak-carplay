THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:14.5
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CarPlayMasterPrefs

CarPlayMasterPrefs_FILES = CPMRootListController.m
CarPlayMasterPrefs_FRAMEWORKS = UIKit CoreGraphics
CarPlayMasterPrefs_PRIVATE_FRAMEWORKS = Preferences
CarPlayMasterPrefs_INSTALL_PATH = /Library/PreferenceBundles
CarPlayMasterPrefs_CFLAGS = -fobjc-arc -I../src

include $(THEOS_MAKE_PATH)/bundle.mk
