# Android device tree for samsung SM-A057(F/G/M) (a05s)

# Maintainers
 - [SavedByLight](https://github.com/SavedByLight)
 - [ravindu644](https://github.com/ravindu644)
 - [Egacyer](https://github.com/egacyer)

# Contributors
 - [Ravindu644](https://github.com/ravindu644) - Custom Kernel Developer, Fixed touch implementation in Chipone
 - [SavedByLight](https://github.com/SavedByLight) - Made the initial tree adding all the TW flags to boardconfig
 - [Egacyer](https://github.com/egacyer) - Maintainer, Himax touchscreen bring-up, touch-release fixes for buttons and the unlock slider, and on-device testing

# Bugs
 - Data Mounting
 - Encrypted /data decryption on One UI 7 / Android 15

# Touchscreen status
 - Himax HX83112F (TXD): driver and firmware loading, button activation, and the unlock slider verified on SM-A057M with One UI 7 / Android 15
 - Button and slider operation require the companion [TWRP input-release fix](https://gerrit.twrp.me/c/android_bootable_recovery/+/8760)
 - Chipone, Goodix, and Ilitek driver files are preserved; hardware regression testing on those variants is still needed

# Kernel
https://github.com/ravindu644/android_kernel_sm_a057f (the work of @ravindu644)

```
#
# Copyright (C) 2025 The Android Open Source Project
# Copyright (C) 2025 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#
```
