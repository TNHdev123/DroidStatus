TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

# 關鍵：開啟 iOS 15+ Rootless 無根架構編譯模組
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DroidStatus

DroidStatus_FILES = Tweak.x
DroidStatus_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
