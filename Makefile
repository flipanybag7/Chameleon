export TARGET := iphone:clang:16.0:13.0
export ARCHS = arm64 arm64e

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
Chameleon_PRIVATE_FRAMEWORKS = MobileGestalt
Chameleon_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
