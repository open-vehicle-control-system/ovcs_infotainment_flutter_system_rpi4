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

SMRT_FLUTTER_PI_DEPENDENCIES += google-libflutter libglvnd mesa3d libinput libxkbcommon xkeyboard-config freetype

SMRT_FLUTTER_PI_CONF_OPTS = \
	-DFLUTTER_ENGINE_SHA=$(SMRT_FLUTTER_PI_ENGINE_HASH) \
	-DLINT_EGL_HEADERS=OFF \
	-DTRY_ENABLE_OPENGL=OFF

# TODO: For some reason this is needed, investigation needed.
define REINSTALL_LIBGLVND_LIBRARIES
	cd $(BASE_DIR) ; make libglvnd-reinstall
endef

SMRT_FLUTTER_PI_PRE_BUILD_HOOKS += REINSTALL_LIBGLVND_LIBRARIES

ifeq ($(BR2_PACKAGE_SMRT_FLUTTER_PI_ENABLE_DEBUG),y)
	SMRT_FLUTTER_PI_CONF_OPTS += \
		-DCMAKE_BUILD_TYPE=Debug \
		-DCMAKE_C_FLAGS="-O1 -Wno-use-after-free"
else
	SMRT_FLUTTER_PI_CONF_OPTS += -DCMAKE_C_FLAGS="-Wno-use-after-free"
endif

$(eval $(cmake-package))
