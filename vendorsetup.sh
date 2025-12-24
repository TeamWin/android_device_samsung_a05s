#
# Copyright (C) 2023 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

# For building with minimal manifest
export ALLOW_MISSING_DEPENDENCIES=true

FDEVICE="taro"

fox_get_target_device() {
local chkdev=$(echo "$BASH_SOURCE" | grep -w $FDEVICE)
	if [ -n "$chkdev" ]; then
		FOX_BUILD_DEVICE="$FDEVICE"
	else
		chkdev=$(set | grep BASH_ARGV | grep -w $FDEVICE)
		[ -n "$chkdev" ] && FOX_BUILD_DEVICE="$FDEVICE"
	fi
}

if [ -z "$1" -a -z "$FOX_BUILD_DEVICE" ]; then
	fox_get_target_device
fi

if [ "$1" = "$FDEVICE" -o "$FOX_BUILD_DEVICE" = "$FDEVICE" ]; then
export LC_ALL="C"
export FOX_DISABLE_APP_MANAGER=1
export FOX_BUILD_TYPE="Beta"
export FOX_VARIANT=AOSP
export FOX_NO_SAMSUNG_SPECIAL=1
export FOX_ENABLE_APP_MANAGER=1
export FOX_INSTALLER_DEBUG_MODE=1
export FOX_DELETE_AROMAFM=0
export FOX_USE_TWRP_RECOVERY_IMAGE_BUILER=1
export FOX_REPLACE_BUSYBOX_PS=0
export FOX_USE_BASH_SHELL=1
export FOX_ASH_IS_BASH=1
export FOX_USE_NANO_EDITOR=1
export FOX_USE_TAR_BINARY=1
export FOX_USE_XZ_UTILS=1
export FOX_USE_SED_BINARY=1
export FOX_RECOVERY_INSTALL_PARTITION=/dev/block/by-name/recovery
export FOX_RECOVERY_SYSTEM_PARTITION=/dev/block/mapper/system
export FOX_RECOVERY_VENDOR_PARTITION=/dev/block/mapper/vendor
export FOX_TARGET_DEVICES=“a05s”

	# Let's see which are our build vars
    if [ -n "$FOX_BUILD_LOG_FILE" -a -f "$FOX_BUILD_LOG_FILE" ]; then
        export | grep "FOX" >> $FOX_BUILD_LOG_FILE
        export | grep "OF_" >> $FOX_BUILD_LOG_FILE
        export | grep "TARGET_" >> $FOX_BUILD_LOG_FILE
        export | grep "TW_" >> $FOX_BUILD_LOG_FILE
    fi
fi