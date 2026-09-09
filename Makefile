THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:14.5
ARCHS = arm64 arm64e

DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CarPlayMaster

CarPlayMaster_FILES = \
	src/Preferences.m \
	src/Window/CPMCarPlayWindow.m \
	src/Hooks/CarPlayAppHooks.xm \
	src/Hooks/SpringBoardHooks.xm \
	src/Hooks/CarKitHooks.xm \
	src/Hooks/StatusBarHooks.xm \
	src/Hooks/AppRotationHooks.xm

CarPlayMaster_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Isrc
CarPlayMaster_FRAMEWORKS = UIKit CoreGraphics QuartzCore Foundation AVFoundation
CarPlayMaster_PRIVATE_FRAMEWORKS = CarKit CarPlayServices CarPlayUI

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += carplaymasterprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
