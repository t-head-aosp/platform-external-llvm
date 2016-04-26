#
# Copyright (C) 2015 The Android Open Source Project
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
#

LOCAL_PATH := $(call my-dir)

libfuzzer_srcs := \
    FuzzerCrossOver.cpp \
    FuzzerInterface.cpp \
    FuzzerTraceState.cpp \
    FuzzerDriver.cpp \
    FuzzerIO.cpp \
    FuzzerLoop.cpp \
    FuzzerMutate.cpp \
    FuzzerSanitizerOptions.cpp \
    FuzzerSHA1.cpp \
    FuzzerUtil.cpp \

include $(CLEAR_VARS)
LOCAL_CLANG := true
LOCAL_MODULE := libLLVMFuzzerNoMain
LOCAL_C_INCLUDES := external/compiler-rt/include
LOCAL_SRC_FILES := $(libfuzzer_srcs)
LOCAL_SANITIZE := never
LOCAL_MULTILIB := both
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_CLANG := true
LOCAL_MODULE := libLLVMFuzzer
LOCAL_SRC_FILES := FuzzerMain.cpp
LOCAL_WHOLE_STATIC_LIBRARIES := libLLVMFuzzerNoMain
LOCAL_SANITIZE := never
LOCAL_MULTILIB := both
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_CLANG := true
LOCAL_MODULE := libLLVMFuzzerNoMain
LOCAL_C_INCLUDES := external/compiler-rt/include
LOCAL_SRC_FILES := $(libfuzzer_srcs)
LOCAL_SANITIZE := never
LOCAL_MULTILIB := both
include $(BUILD_HOST_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_CLANG := true
LOCAL_MODULE := libLLVMFuzzer
LOCAL_SRC_FILES := FuzzerMain.cpp
LOCAL_WHOLE_STATIC_LIBRARIES := libLLVMFuzzerNoMain
LOCAL_SANITIZE := never
LOCAL_MULTILIB := both
include $(BUILD_HOST_STATIC_LIBRARY)
