################################################################################
#
# google-libflutter
# builds the Flutter engine, DartVM and AOT compiler for ARM platforms
#
################################################################################

# Find the engine.version file for the version of Flutter you want to build.
#
# It will be at:
#    https://raw.githubusercontent.com/flutter/flutter/$(FLUTTER_VERSION)/bin/internal/engine.version
#
# Then copy the contens of the file here.
GOOGLE_LIBFLUTTER_VERSION = 04817c99c9fd4956f27505204f7e344335810aed # 3.19.0
GOOGLE_LIBFLUTTER_SOURCE =

################################################################################

define GOOGLE_LIBFLUTTER_CONFIGURE_CMDS
	echo "$(GOOGLE_LIBFLUTTER_VERSION)" > $(@D)/engine.version
	#cp $(GOOGLE_LIBFLUTTER_DL_DIR)/$(GOOGLE_LIBFLUTTER_SOURCE) $(@D)
endef

ifeq ($(BR2_PACKAGE_GOOGLE_LIBFLUTTER_ENABLE_DEBUG),y)
define GOOGLE_LIBFLUTTER_INSTALL_TARGET_CMDS
	cp $(@D)/build/out/linux_release_*/libflutter_engine.so $(TARGET_DIR)/usr/lib
	cp $(@D)/build/out/linux_debug_*/lib.unstripped/libflutter_engine.so $(TARGET_DIR)/usr/lib/libflutter_engine.so.debug
	cp $(@D)/build/out/linux_release_*/icudtl.dat $(TARGET_DIR)/usr/lib
endef
else
define GOOGLE_LIBFLUTTER_INSTALL_TARGET_CMDS
	cp $(@D)/build/out/linux_release_*/libflutter_engine.so $(TARGET_DIR)/usr/lib
	cp $(@D)/build/out/linux_release_*/icudtl.dat $(TARGET_DIR)/usr/lib
endef
endif


################################################################################


GOOGLE_LIBFLUTTER_DEPENDENCIES = mesa3d libinput libxkbcommon xkeyboard-config freetype
GOOGLE_LIBFLUTTER_LICENSE = BSD-3-Clause

ifeq ($(BR2_PACKAGE_GOOGLE_LIBFLUTTER_ENABLE_DEBUG),y)
define GOOGLE_LIBFLUTTER_BUILD_CMDS
	$(NERVES_DEFCONFIG_DIR)/packages/google-libflutter/build-engine.sh $(@D) $(HOST_DIR) release $(BR2_TOOLCHAIN_EXTERNAL_PREFIX)
	$(NERVES_DEFCONFIG_DIR)/packages/google-libflutter/build-engine.sh $(@D) $(HOST_DIR) debug $(BR2_TOOLCHAIN_EXTERNAL_PREFIX)
endef
else
define GOOGLE_LIBFLUTTER_BUILD_CMDS
	$(NERVES_DEFCONFIG_DIR)/packages/google-libflutter/build-engine.sh $(@D) $(HOST_DIR) release $(BR2_TOOLCHAIN_EXTERNAL_PREFIX)
endef
endif

$(eval $(generic-package))
