include device/lge/mt6575-common/BoardConfigCommon.mk

TARGET_BOOTLOADER_BOARD_NAME := vee4ss

# Physical panel: HVGA portrait. CM uses the smaller dimension to select the
# matching boot animation, so this picks vendor/cm's 320.zip instead of the
# 480.zip fallback from common_full_phone.mk.
TARGET_SCREEN_WIDTH := 320
TARGET_SCREEN_HEIGHT := 480

# ---- Kernel prebuilt ----
TARGET_PREBUILT_KERNEL := device/lge/vee4ss/kernel

# Partition sizes (de /proc/dumchar_info del dispositivo real, 2026-07-22)
BOARD_BOOTIMAGE_PARTITION_SIZE     := 8388608
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 7340032
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 1132462080
BOARD_USERDATAIMAGE_PARTITION_SIZE := 2232680448

# ---- Recovery ----
TARGET_RECOVERY_FSTAB := device/lge/vee4ss/ramdisk/recovery/twrp.fstab
# Almacenamiento interno via datamedia (/data/media)
RECOVERY_SDCARD_ON_DATA := true

# ---- OTA assert ----
TARGET_OTA_ASSERT_DEVICE := vee4ss,E440g,LG-E440g

# The E44010a LED driver has led_current_index (lights HAL mode 4)
BOARD_LP5521_HAS_CURRENT_INDEX := true
