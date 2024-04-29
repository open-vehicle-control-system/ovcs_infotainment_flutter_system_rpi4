################################################################################
#
# smrt-flutter-pi
#
#################################################################################

SMRT_FLUTTER_PI_VERSION = v0.3.1
SMRT_FLUTTER_PI_SITE = $(call github,smartrent,flutter-pi,$(SMRT_FLUTTER_PI_VERSION))

SMRT_FLUTTER_PI_LICENSE = MIT
SMRT_FLUTTER_PI_LICENSE_FILES = LICENSE

# THIS MUST MATCH THE ENGINE SHA1 OF GOOGLE_LIBFLUTTER
SMRT_FLUTTER_PI_ENGINE_HASH=04817c99c9fd4956f27505204f7e344335810aed

ifeq ($(BR2_PACKAGE_SMRT_FLUTTER_PI_ENABLE_DEBUG),y)
	SMRT_FLUTTER_PI_CONF_OPTS = -DCMAKE_C_FLAGS="-O1 -Wno-use-after-free" -DFLUTTER_ENGINE_SHA=$(SMRT_FLUTTER_PI_ENGINE_HASH) -DCMAKE_BUILD_TYPE=Debug
else
	SMRT_FLUTTER_PI_CONF_OPTS = -DCMAKE_C_FLAGS="-Wno-use-after-free" -DFLUTTER_ENGINE_SHA=$(SMRT_FLUTTER_PI_ENGINE_HASH)
endif

SMRT_FLUTTER_PI_DEPENDENCIES = mesa3d libinput libxkbcommon xkeyboard-config libuev libglvnd

$(eval $(cmake-package))
