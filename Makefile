export TARGET := iphone:clang:16.0:13.0
export ARCHS = arm64 arm64e
export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Chameleon
Chameleon_FILES = Tweak.xm \
                  UIDeviceHooks.xm \
                  MGCopyAnswerHooks.xm \
                  ASIdentifierHooks.xm \
                  CanvasHooks.xm \
                  SysctlHooks.xm \
                  IOKitHooks.xm \
                  NetworkHooks.xm \
                  CHIdentityEngine.m

Chameleon_CFLAGS = -fobjc-arc -I.
Chameleon_FRAMEWORKS = UIKit Foundation CoreGraphics Security AdSupport WebKit CoreTelephony
Chameleon_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = chameleonprefs
chameleonprefs_FILES = CHPRootListController.m CHIdentityEngine.m
chameleonprefs_INSTALL_PATH = /Library/PreferenceBundles
chameleonprefs_CFLAGS = -fobjc-arc -I.
chameleonprefs_RESOURCES = Specifiers.plist
chameleonprefs_LDFLAGS = -undefined dynamic_lookup
chameleonprefs_FRAMEWORKS = UIKit Foundation CoreGraphics Security

include $(THEOS_MAKE_PATH)/bundle.mk
