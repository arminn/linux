# Copyright (C) 2018 The Android Open Source Project
# Copyright (C) 2021 EPAM Systems Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Based on https://android.googlesource.com/kernel/msm/

ifneq ($(filter xenvm, $(TARGET_PRODUCT)),)

# Build kernel inside Android tree
ifeq ($(TARGET_PREBUILT_KERNEL),)

LOCAL_PATH := $(call my-dir)

KERNEL_SRC                  := $(abspath $(TARGET_KERNEL_SOURCE))
KERNEL_DEFCONFIG := $(TARGET_KERNEL_CONFIG)
KERNEL_CONFIG := $(KERNEL_OUT)/.config
KERNEL_TARGET_BINARY := $(KERNEL_OUT)/arch/$(TARGET_ARCH)/boot/Image
KERNEL_CFLAGS := LD=ld.lld HOSTCC=$(ANDROID_CLANG_TOOLCHAIN) ARCH=arm64
KERNEL_CFLAGS += CC=$(ANDROID_CLANG_TOOLCHAIN) HOSTCFLAGS="-fuse-ld=lld" LLVM=1 LLVM_IAS=1 AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump
KERNEL_CFLAGS += OBJSIZE=llvm-size READELF=llvm-readelf STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi-

$(BOARD_VENDOR_KERNEL_MODULES): $(KERNEL_EXT_MODULES)

$(KERNEL_OUT):
	mkdir -p $(KERNEL_OUT)

$(KERNEL_MODULES_OUT):
	mkdir -p $(KERNEL_MODULES_OUT)

$(KERNEL_CONFIG): $(KERNEL_OUT)
	PATH=$(ANDROID_CLANG_TOOLCHAIN):$$PATH TEMPORARY_DISABLE_PATH_RESTRICTIONS=true  LD=ld.lld $(ANDROID_MAKE) -C $(KERNEL_SRC) O=$(KERNEL_OUT_ABS) $(KERNEL_CFLAGS) $(KERNEL_DEFCONFIG)

$(KERNEL_TARGET_BINARY): $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_MODULES_OUT)
	LD=ld.lld $(ANDROID_MAKE) CONFIG_DEBUG_SECTION_MISMATCH=y -C $(KERNEL_SRC) O=$(KERNEL_OUT_ABS) $(KERNEL_CFLAGS) Image -j `$(NPROC)`

$(KERNEL_MODULES): $(KERNEL_TARGET_BINARY)
	@rm -rf $(KERNEL_MODULES_OUT)/lib/modules
	LD=ld.lld $(ANDROID_MAKE) -C $(TARGET_KERNEL_SOURCE) O=$(KERNEL_OUT_ABS) INSTALL_MOD_PATH=$(KERNEL_MODULES_OUT_ABS) $(KERNEL_CFLAGS) modules
	$(ANDROID_MAKE) -C $(TARGET_KERNEL_SOURCE) O=$(KERNEL_OUT_ABS) INSTALL_MOD_PATH=$(KERNEL_MODULES_OUT_ABS) $(KERNEL_CFLAGS) modules_install
	find $(KERNEL_MODULES_OUT) -mindepth 2 -type f -name '*.ko' | grep "$(shell head -1 $(KERNEL_OUT_ABS)/include/config/kernel.release)" | $(XARGS) -I{} mv {} $(KERNEL_MODULES_OUT)/

$(PRODUCT_OUT)/kernel: $(KERNEL_TARGET_BINARY) $(KERNEL_MODULES)
	cp -v $(KERNEL_TARGET_BINARY) $(PRODUCT_OUT)/kernel

endif # TARGET_PREBUILT_KERNEL

endif # TARGET_PRODUCT
