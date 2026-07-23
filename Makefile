TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := MyAutoClicker
MyAutoClicker_FILES := Tweak.x
MyAutoClicker_CFLAGS := -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
