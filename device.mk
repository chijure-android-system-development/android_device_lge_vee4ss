PRODUCT_DEVICE := vee4ss
PRODUCT_NAME := omni_vee4ss
PRODUCT_BRAND := lge
PRODUCT_MODEL := LG-E440g
PRODUCT_MANUFACTURER := LGE

PRODUCT_COPY_FILES += \
    device/lge/vee4ss/ramdisk/init.recovery.mt6575.rc:root/init.recovery.mt6575.rc \
    device/lge/vee4ss/ramdisk/sbin/postrecoveryboot.sh:root/sbin/postrecoveryboot.sh

PRODUCT_PACKAGES += \
    adbd

# Recovery ADB defaults. ro.secure=0 y ro.debuggable=1 ya vienen del
# build omni_vee4ss-eng; esto son los defaults de USB/ADB específicos del device.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.adb.secure=0 \
    persist.service.adb.enable=1 \
    service.adb.root=1
