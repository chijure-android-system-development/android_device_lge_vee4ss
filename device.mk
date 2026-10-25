$(call inherit-product, device/lge/mt6575-common/mt6575-common.mk)

DEVICE_PACKAGE_OVERLAYS += device/lge/vee4ss/overlay

PRODUCT_DEVICE       := vee4ss
PRODUCT_NAME         := cm_vee4ss
PRODUCT_BRAND        := lge
PRODUCT_MODEL        := LG-E440g
PRODUCT_MANUFACTURER := LGE

# ---- Pantalla 320x480 HVGA, 160 dpi; ~486 MB RAM ----
# Mismos valores que el mdpi-dalvik.mk del LG E610 oficial de CyanogenMod
# (320x480 mdpi); el perfil hdpi-512 (48m/128m) es para pantallas más grandes.
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=5m \
    dalvik.vm.heapgrowthlimit=32m \
    dalvik.vm.heapsize=96m \
    ro.sf.lcd_density=160

PRODUCT_AAPT_CONFIG      := normal mdpi
PRODUCT_AAPT_PREF_CONFIG := mdpi

# USB defaults to MTP; post_process_props appends ",adb" on userdebug builds.
# Kept out of build.prop, which loads after default.prop and would override it.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.adb.secure=0 \
    service.adb.root=1 \
    persist.sys.usb.config=mtp

# ---- Init: init.mt6575.rc imports the common one ----
PRODUCT_COPY_FILES += \
    device/lge/vee4ss/rootdir/init.mt6575.rc:root/init.mt6575.rc \
    device/lge/vee4ss/rootdir/init.mt6575.usb.rc:root/init.mt6575.usb.rc

# ---- Media: MTK hardware codecs (common media_codecs.xml), 640x480 ----
# Each device picks its media_codecs.xml: a product's PRODUCT_COPY_FILES
# do not override an inherited one with the same destination. The MTK
# codec blobs come from vendor/lge/vee4ss.
PRODUCT_COPY_FILES += \
    device/lge/mt6575-common/rootdir/system/etc/media_codecs.xml:system/etc/media_codecs.xml \
    device/lge/vee4ss/media_profiles.xml:system/etc/media_profiles.xml

PRODUCT_PACKAGES += \
    libstagefrighthw
