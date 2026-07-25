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
BOARD_RECOVERY_SWIPE := true
TARGET_RECOVERY_FSTAB := device/lge/vee4ss/ramdisk/recovery/twrp.fstab

# NO poner TW_EXCLUDE_DEFAULT_USB_INIT aquí — se probó (2026-07-23) y aunque en
# teoría bootable/recovery/etc/init.recovery.usb.rc (genérico) es redundante con
# nuestro init.recovery.mt6575.rc, sacarlo del build rompió ADB por completo
# (USB quedaba en "offline", idVendor/idProduct nunca se configuraban), reproducible
# en 2 reboots seguidos. Con el archivo genérico presente, ADB conecta bien de
# forma confiable (confirmado en varios reboots) aunque quede un error cosmético
# en el log de init por `${ro.serialno}` sin resolver — no tocar esto de nuevo
# sin poder probar varios ciclos de reboot antes de darlo por bueno.

# El campo Serial de /proc/cpuinfo da puros ceros en este MT6575, así que el
# device_id por defecto de TWRP (usado para el nombre de la carpeta de backup)
# sale como "0000000000000000". Usar el modelo del producto en su lugar
# (-> "LG-E440g"). En teoría debería agregar también el campo Hardware de
# cpuinfo (-> "LG-E440g_MT6575"), pero DataManager::get_device_id() en
# bootable/recovery/data.cpp abre "proc_cpuinfo.txt" (ruta relativa, no
# "/proc/cpuinfo") para ese campo — el fopen falla en silencio y el sufijo
# nunca se agrega. Confirmado en hardware real (2026-07-23): el nombre final
# es solo "LG-E440g", igual de limpio, no vale la pena tocar el código
# compartido de TWRP por esto.
TW_USE_MODEL_HARDWARE_ID_FOR_DEVICE_ID := true

# TWRP UI: pantalla 320x480 HVGA (ili9486_hvga_dsi_cmd, 32bpp framebuffer)
TW_THEME := portrait_mdpi
TARGET_RECOVERY_PIXEL_FORMAT := "RGBA_8888"

# Almacenamiento interno via datamedia (/data/media)
RECOVERY_SDCARD_ON_DATA := true
TW_INTERNAL_STORAGE_PATH := "/data/media"
TW_INTERNAL_STORAGE_MOUNT_POINT := "data"
TW_EXTERNAL_STORAGE_PATH := "/external_sd"
TW_EXTERNAL_STORAGE_MOUNT_POINT := "external_sd"

TARGET_USE_CUSTOM_LUN_FILE_PATH := /sys/devices/virtual/android_usb/android0/f_mass_storage/lun/file
TW_HAS_MTP := true
TW_MTP_DEVICE := /dev/mtp_usb

TW_NO_EXFAT := true
TW_DEVICE_VERSION := 0.1
TW_INCLUDE_CRYPTO := false
TW_EXCLUDE_SUPERSU := true
TW_NO_REBOOT_BOOTLOADER := true

TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 128
TW_NO_CPU_TEMP := true

BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_VOLD_MAX_PARTITIONS := 30

# Charger mode: MTK power-off charging detectado via androidboot.mode=charger
BOARD_GLOBAL_CFLAGS += -DCHARGERMODE_CMDLINE_NAME='"androidboot.mode"' -DCHARGERMODE_CMDLINE_VALUE='"charger"'
