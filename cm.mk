$(call inherit-product, device/lge/vee4ss/device.mk)
$(call inherit-product-if-exists, vendor/lge/vee4ss/vee4ss-vendor-blobs.mk)
$(call inherit-product, vendor/cm/config/common_full_phone.mk)

PRODUCT_NAME     := cm_vee4ss
PRODUCT_DEVICE   := vee4ss
PRODUCT_BRAND    := lge
PRODUCT_MODEL    := LG-E440g
PRODUCT_MANUFACTURER := LGE
PRODUCT_RELEASE_NAME := L4 II

PRODUCT_BUILD_PROP_OVERRIDES += \
    BUILD_FINGERPRINT="lge/vee4ss_sca_com_g/vee4ss:4.1.2/JZO54K/f9e280bda5:user/release-keys" \
    PRIVATE_BUILD_DESC="vee4ss_sca_com_g-user 4.1.2 JZO54K f9e280bda5 release-keys" \
    BUILD_NUMBER=f9e280bda5
