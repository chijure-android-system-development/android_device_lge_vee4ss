# ---- SoC / CPU (MediaTek MT6575) ----
TARGET_BOARD_PLATFORM := mt6575
TARGET_BOOTLOADER_BOARD_NAME := vee4ss
BOARD_VENDOR := lge

TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9
TARGET_ARCH_LOWMEM := true

TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true

# ---- Full ROM build (CM10) ----
TARGET_RELEASETOOLS_EXTENSIONS := device/lge/vee4ss
TARGET_PROVIDES_INIT_RC := true
TARGET_OTA_ASSERT_DEVICE := vee4ss,E440g,LG-E440g
BOARD_USES_LEGACY_CAMERA := true
ADDITIONAL_DEFAULT_PROPERTIES += ro.secure=0

# WiFi — driver como módulo kernel (wlan.ko), interfaz nl80211
# NOTE: this must live here, NOT in vendor/lge/vee4ss/BoardConfigVendor.mk —
# this build system has no automatic vendor BoardConfig include mechanism,
# so that file is never read. (vee5ss's copy is equally dead; its real
# values live directly in device/lge/vee5ss/BoardConfig.mk, same as here.)
BOARD_WLAN_DEVICE           := MT6620
WPA_SUPPLICANT_VERSION      := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_mt66xx
BOARD_HOSTAPD_DRIVER        := NL80211
BOARD_HOSTAPD_PRIVATE_LIB   := lib_driver_cmd_mt66xx
WIFI_DRIVER_MODULE_PATH     := /system/lib/modules/wlan.ko
WIFI_DRIVER_MODULE_NAME     := wlan

# Bluetooth — MT6620 combo via UART
BOARD_HAVE_BLUETOOTH        := true
BOARD_HAVE_BLUETOOTH_MTK    := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/lge/vee4ss/bluetooth

# ---- Kernel prebuilt ----
TARGET_PREBUILT_KERNEL := device/lge/vee4ss/kernel

# MTK boot image: base=0x10000000 → kernel@0x10008000, ramdisk@0x11000000
BOARD_KERNEL_BASE := 0x10000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_CMDLINE := androidboot.hardware=mt6575
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x01000000 --tags_offset 0x00000100

# mtkbootimg: custom mkbootimg que añade headers MTK al kernel y ramdisk
BOARD_CUSTOM_BOOTIMG := true
BOARD_CUSTOM_MKBOOTIMG := $(HOST_OUT_EXECUTABLES)/mtkbootimg$(HOST_EXECUTABLE_SUFFIX)
BOARD_CUSTOM_BOOTIMG_MK := device/lge/vee4ss/bootimg.mk

# Partition sizes (de /proc/dumchar_info del dispositivo real, 2026-07-22)
BOARD_BOOTIMAGE_PARTITION_SIZE    := 8388608
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 7340032
BOARD_SYSTEMIMAGE_PARTITION_SIZE  := 1132462080
BOARD_USERDATAIMAGE_PARTITION_SIZE := 2232680448
BOARD_FLASH_BLOCK_SIZE := 131072

TARGET_USERIMAGES_USE_EXT4 := true

# Recovery
BOARD_HAS_NO_SELECT_BUTTON := true
BOARD_HAS_NO_MISC_PARTITION := true
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_SUPPRESS_EMMC_WIPE := true
BOARD_USES_MMCUTILS := true
TARGET_RECOVERY_FSTAB := device/lge/vee4ss/ramdisk/recovery/twrp.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBA_8888"

# Almacenamiento interno via datamedia (/data/media)
RECOVERY_SDCARD_ON_DATA := true

# ---- ADB root (útil durante el desarrollo del port) ----
ADDITIONAL_DEFAULT_PROPERTIES += ro.secure=0

# ---- Charger mode (MTK detecta vía androidboot.mode=charger) ----
BOARD_GLOBAL_CFLAGS += -DCHARGERMODE_CMDLINE_NAME='"androidboot.mode"' \
                       -DCHARGERMODE_CMDLINE_VALUE='"charger"'

# ---- Filesystem ----
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_VOLD_MAX_PARTITIONS   := 30
