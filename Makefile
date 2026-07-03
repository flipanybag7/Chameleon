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
                  CHIdentityEngine.m \
                  CHPRootListController.m

Chameleon_CFLAGS = -fobjc-arc -I.
Chameleon_LDFLAGS = -undefined dynamic_lookup
Chameleon_FRAMEWORKS = UIKit Foundation CoreGraphics Security AdSupport WebKit CoreTelephony
Chameleon_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
