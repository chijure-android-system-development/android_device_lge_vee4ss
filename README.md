# LG Optimus L4 II (vee4ss) - TWRP and CyanogenMod 10

**Device**: LG-E440g
**Codename**: vee4ss
**SoC**: MediaTek MT6575
**CPU**: ARM Cortex-A9
**Android base**: 4.1.2 (JZO54K)
**Stock product**: `lge/vee4ss_sca_com_g/vee4ss`

**Status: confirmed working on real hardware (2026-07-23).** Boots clean, touch
responsive, internal/external storage mounted, MTP working, ADB reliable across
repeated reboot cycles.

## CyanogenMod 10 port status (real hardware, 2026-07-29)

CM10 boots to Android and the display, boot animation and ADB have been
confirmed on an LG-E440g. The display fix is **not contained entirely in this
device tree**: LG's proprietary MT6575 graphics blobs use MediaTek extensions
to the Jelly Bean HWC/GraphicBuffer ABI which are absent from AOSP/CM10.
Consequently, the following CM10 source changes must be kept together with
`device/lge/vee4ss` when reproducing the build.

### Changes outside the device tree

| CM10 project | Modified area | Reason |
|--------------|---------------|--------|
| `hardware/libhardware` | `include/hardware/hwcomposer.h` | Adds the private MT6575 fields to `hwc_layer_t` (132-byte layer) and `hwc_layer_list_t` (16-byte header). |
| `frameworks/native` | `libui`, `libgui` and SurfaceFlinger | Restores the stock `GraphicBuffer`/MMU mapper ABI, fills the MTK layer fields and sends the private presentation flag required by the proprietary HWC. |
| `frameworks/base` | BlueAngel Bluetooth, telephony | MT6620 Bluetooth stack (see below) and the GSMPhone/IccCard MTK fixes. |

These platform changes are temporary and are kept as patch files in
`patches/<project>/`, applied as uncommitted changes (nothing is committed
to the CyanogenMod repositories). From the top of the tree:

```bash
device/lge/vee4ss/patches/apply-patches.sh    # skips series already present
device/lge/vee4ss/patches/revert-patches.sh   # back to plain CM10
```

The goal is to keep moving them into the device tree as HALs/wrappers.

Everything else that used to be patched in the platform now lives in this
device tree (2026-10-24):

| Device tree | Replaces | What it does |
|-------------|----------|--------------|
| `audio/` (`audio.primary.mt6575`) | `hardware/libhardware` id-check bypass | The stock `libaudio.primary.default.so` reports module id `libaudio`, which `hw_get_module_by_class()` rejects; the wrapper carries the right id and opens the device through the blob. |
| `libmtk_symbols/` + `LD_PRELOAD` in `init.mt6575.rc` | `system/core` liblog patch | Provides `__xlog_buf_printf` for the vendor blobs; the 4.1 linker searches preloads first. |
| `include/cutils/xlog.h` | `system/core` header | XLOG macros for the BlueAngel sources in `frameworks/base`. |
| `camera/camera_wrapper.c` | `frameworks/av` CameraSource NULL check | Adds `video-frame-format=yuv420sp`, which the stock HAL never sets. |
| `media_profiles.xml` | — | High profile is m4v 320x240: H.263 only takes standard sizes and the encoder failed to start at 320x240. |
| `overlay/packages/apps/LegacyCamera` | — | 68dp control bar (was 105dp) so the 4:3 preview fills the HVGA screen. |
| `lights/lights.c` | — | Stock `lights.default.so` behaviour, plus LG's EmotionalLedService charging LED. |
| `ril/` (`libvee4ss-ril`, `rild.libpath`) | `hardware/ril` rild patch | Gives `mtk-ril.so` MediaTek's six-entry `RIL_Env` from MTK's libril (proxy timed callback, AT channel and proxy id) instead of stubs, and waits for `/dev/radio/pttycmd1`. Fixes the `requestRadioPower` crash. |

The graphics ABI additions are enabled with `VEE4SS_MTK_HWC_ABI`. Its build
flag is limited to `TARGET_DEVICE=vee4ss` in the Android.mk files for
SurfaceFlinger, `libui` and `libgui`, so other CM10 targets retain the standard
ABI.

The decisive black-screen fix is in
`frameworks/native/services/surfaceflinger/DisplayHardware/HWComposer.cpp`:
before calling the vendor HWC `set()`, SurfaceFlinger sets private list bit
`0x2` (`LAYERS_SWAP_REQUIRED`). Without that bit Android reaches
`sys.boot_completed=1`, but the MTK HWC never posts the composed framebuffer.
The work list is also allocated with `calloc()` because the vendor blob reads
the added private fields.

`GraphicBuffer` includes the stock MT6575 `mMva`/`mSize` members and the
`mmumapper` map/unmap interface. SurfaceFlinger passes the `GraphicBuffer*`,
alpha and 3x3 transform expected by the blob. RGB UI buffers are not sent to
the MMU mapper because the stock mapper rejects those formats.

### Device-tree changes needed by CM10

- `/dev/mtkfb_vsync` is owned by `system:graphics` with mode `0660`, allowing
  SurfaceFlinger/HWC to receive VSYNC events.
- USB defaults to `mtp,adb`: `persist.sys.usb.config=mtp` goes to
  `default.prop` (userdebug appends `,adb`), not to `build.prop`, which loads
  later and would override it.
- The physical screen is declared as HVGA `320x480`, mdpi/160 dpi.
- `TARGET_SCREEN_WIDTH` and `TARGET_SCREEN_HEIGHT` are set at the beginning of
  `cm.mk`, before inheriting CM's common product configuration. This selects
  `vendor/cm/prebuilt/common/bootanimation/320.zip`; setting the dimensions
  only in `BoardConfig.mk` is too late and causes the oversized 480px fallback.

### CM10 build

Use the project Docker builder on the native Docker engine (Docker Desktop's
shared folders are slow and can serve stale files); the source tree is
mounted at `/home/builder/cm10` inside the container:

```bash
docker --context default exec cm10-builder bash -lc '
cd /home/builder/cm10 && DEVICE=vee4ss ./timed_build.sh'
```

After changing a property in `device.mk`, delete
`out/target/product/vee4ss/system/build.prop` and `root/default.prop` first:
they are not regenerated otherwise. The OTA zip only updates `/system`; flash
`boot.img` separately.

Before distributing a build, verify that the generated system contains the
320px animation:

```bash
unzip -p out/target/product/vee4ss/system/media/bootanimation.zip desc.txt
# Expected first line: 320 320 24
```

Do not replace the complete CM10 `libui`/`libgui`/SurfaceFlinger stack with
stock LG binaries. That experiment was incompatible with CM10's internal
Binder and object layouts; the working configuration uses the CM10 components
compiled with the compatibility changes described above.

### Bluetooth MT6620 / BlueAngel (working, 2026-07-29)

Bluetooth uses LG/MediaTek's proprietary BlueAngel stack, not CM10's default
BlueZ/rfkill path. The unmodified CM10 backend aborts while enabling because
this kernel has no Bluetooth entry at `/sys/class/rfkill/rfkill0`; MT6620 is
controlled through WMT/STP, `/dev/stpbt` and `/system/bin/mtkbt` instead.

The working port adds the MediaTek Bluetooth integration to
`frameworks/base`: the BlueAngel versions of `BluetoothService`,
`BluetoothEventLoop`, A2DP and socket JNI, the profile manager/socket Binder
services, the additional Java/AIDL APIs in `framework2.jar`, and registration
from `SystemServer`. `libandroid_runtime` is compiled with `__BTMTK__` and links
the stock `libmtkbtextadpa2dp` and `libextjsr82` blobs. `servicemanager` also
allows the Bluetooth UID to register the `mtk.bt.profile.*.ashm` services.

The companion changes in `packages/apps/Bluetooth` bound or terminate accept
threads cleanly during shutdown. `packages/apps/Phone` checks that the
BlueAngel SCO server socket exists before closing it; without that check,
turning Bluetooth off reaches `STATE_OFF` but crashes and restarts
`com.android.phone`.

Confirmed on the E440g:

- `STATE_OFF (10) -> STATE_ON (12) -> STATE_OFF (10)`.
- Local controller address read correctly as `30:76:6F:AB:C1:17`.
- Classic discovery starts, reports real devices and their SDP UUIDs.
- `mtkbt`, `system_server`, `com.android.bluetooth` and `com.android.phone`
  remain alive across a complete on/off cycle.
- Binder services `bluetooth_profile_manager` and `bluetooth_socket`, plus the
  SPP/OPP/FTP/JSR82 shared-memory services, are registered.

Files that must be rebuilt and installed together after changing this port:

```text
/system/lib/libandroid_runtime.so
/system/framework/framework.jar
/system/framework/framework2.jar
/system/framework/services.jar
/system/app/Bluetooth.apk
/system/app/Phone.apk
/system/bin/servicemanager
```

Partial build command used during validation:

```bash
docker exec cm10-builder bash -lc '
cd /home/builder/cm10 &&
source build/envsetup.sh >/dev/null &&
lunch cm_vee4ss-eng >/dev/null &&
make -j4 libandroid_runtime framework framework2 services \
    Bluetooth Phone servicemanager
'
```

The initial local-name, scan-mode and local-UUID requests contain compatibility
guards for this specific `mtkbt` binary. The daemon does not implement its
advertised local-UUID request; later scan-mode changes and discovery are sent
normally. Pairing, A2DP audio and file transfer still need separate end-to-end
tests even though their services initialize without fatal errors.

Based on the already hardware-verified [`device/lge/vee5ss`](../vee5ss/) tree
(LG-E450g, same MT6575 SoC, same LG family). Boot image layout and MTK partition
structure are identical between the two; what differs is the screen (HVGA vs
WVGA), the USB gadget product ID, and the real partition sizes/numbers.

## Partitions

Taken from `/proc/dumchar_info` on the real device (2026-07-22).

| Partition | Device | Size |
|-----------|--------|------|
| bootimg | `/dev/bootimg` | 8 MiB |
| recovery | `/dev/recovery` | 7 MiB |
| system (`android`) | `/dev/block/mmcblk0p8` | ~1.05 GiB |
| cache | `/dev/block/mmcblk0p9` | ~308 MiB |
| usrdata | `/dev/block/mmcblk0p10` | ~2.08 GiB |
| fat | `/dev/block/mmcblk0p11` | ~10.5 MiB (unused by TWRP) |
| external SD | `/dev/block/mmcblk1p1` | variable |

`misc`/`misc2` also exist as MTK virtual partitions but are **not** used for
boot-mode selection on this device (see Known issues below) and are not part
of the fstab.

## Notes

- The prebuilt kernel (`kernel`, no MTK header) was extracted from a
  `boot_raw.img` backup taken before touching the bootloader, using
  `abootimg -x`, then stripped of its 512-byte MTK header (`tail -c +513`) —
  `mtkbootimg --mtk 1` adds it back at build time, same as vee5ss. **Use the
  original LG kernel, not one from a custom ROM** (needed for KPOC / power-off
  charging drivers).
- Boot image layout (confirmed with `abootimg -i` on `boot_raw.img`):
  `base=0x10000000`, `pagesize=2048`, `ramdisk_offset=0x01000000`,
  `tags_offset=0x00000100` — identical to the E450g.
- Screen: **320x480 HVGA** (`lcm=1-ili9486_hvga_dsi_cmd` in `/proc/cmdline`,
  `ro.sf.lcd_density=160`), 32bpp framebuffer at the Android compositor level
  (`fb0/bits_per_pixel=32`, `fb0/virtual_size=320,960`, double buffered).
  `TW_THEME := portrait_mdpi` — matches what TWRP's autodetect would pick
  anyway for width < 720 (see `bootable/recovery/gui/Android.mk`), set
  explicitly for clarity.
- USB gadget PID: `idVendor 1004` / `idProduct 631F` for normal Android,
  confirmed by reading `/sys/class/android_usb/android0/idProduct` live on the
  device — **different from the E450g's `61F1`**. Don't assume the same PID
  across models in this family; always read it from the actual device.
- Internal storage is handled as `/data/media` with
  `RECOVERY_SDCARD_ON_DATA := true`.
- `TW_NO_REBOOT_BOOTLOADER := true` because the LG-E440g does not expose
  standard fastboot (it's MTK).
- The MT6575 kernel leaves the button-backlight LED in a `timer` blink trigger
  by default; `postrecoveryboot.sh` (identical to vee5ss's, same LP5521 LED
  hardware confirmed via `/sys/class/leds/`) clears it at boot.

## Known issues / lessons learned on real hardware

- **`bits_per_pixel` mismatch is normal, not a bug.** TWRP's own framebuffer
  probe at boot reports `bits_per_pixel=16` (RGB_565) via a direct `fbdev`
  ioctl, even though `BoardConfig.mk` sets `TARGET_RECOVERY_PIXEL_FORMAT :=
  "RGBA_8888"` and Android's own compositor reports 32bpp. This is the normal
  gap between the raw fbdev driver (recovery) and SurfaceFlinger (normal
  Android) on this panel — the UI renders and responds to touch correctly
  either way.
- **`/misc` is not used for boot-mode selection on this device.** Verified by
  dumping `/dev/misc` (all zero bytes) from both TWRP and a fully-booted stock
  Android, and again immediately after Android's own `adb reboot recovery`
  request — content never changes. This MT6575/LK combination does not use
  the classic Android BCB struct in `/misc` the way Qualcomm devices (e.g. the
  LG-C660h) do; it must rely on something else (likely an RTC/PMIC scratch
  register read by the LK bootloader). `BOARD_HAS_NO_MISC_PARTITION := true`
  is correct here — do not add `/misc` to the fstab or try to use it.
- **Do not set `TW_EXCLUDE_DEFAULT_USB_INIT := true`.** In theory this device
  tree's own `init.recovery.mt6575.rc` (plain `f_adb`, not FunctionFS) makes
  the generic `bootable/recovery/etc/init.recovery.usb.rc` (FunctionFS-based,
  Google's `idVendor 18D1`) redundant, and excluding it would also fix a
  cosmetic init error (see below). **Tested on real hardware and it broke USB
  completely** — with the flag set, ADB stayed `offline` reproducibly across
  every reboot to recovery, with neither file's `idVendor`/`idProduct` ever
  taking effect. Reverting the flag restored reliable ADB across multiple
  reboot cycles. The root cause of why our own USB init isn't sufficient on
  its own was not tracked down — left as a known limitation rather than risk
  breaking connectivity again.
- **Cosmetic-only init error**: `init: cannot expand '${ro.serialno}'` appears
  in `dmesg` on every boot. The bootloader doesn't pass `androidboot.serialno`
  on the kernel cmdline and there's no LG service in the minimal recovery
  ramdisk to populate it, so `ro.serialno` never exists in recovery. This is
  why `adb devices` shows a generic placeholder serial in recovery instead of
  the phone's real one. Harmless — ADB still works, host-side driver matching
  uses USB interface class, not the reported serial or `idVendor`/`idProduct`.
- Missing spinner frame: `Failed to load image from indeterminate013` in
  `portrait_mdpi` — one animation frame not found, purely cosmetic.

## Entering recovery mode

Not yet confirmed via hardware button combo — all testing so far went through
`adb reboot recovery` with root already available. The E450g combo (Vol+,
Vol−, Action button, Power) may or may not carry over; the E440g may lack the
same center Action key. Update this section once confirmed.

## Build

The Android 4.4 tree expects an old Java toolchain, so the known-good build
path is the Docker builder container.

```bash
docker exec twrp-4.4-builder bash -lc '
cd /home/builder/twrp-4.4 &&
source build/envsetup.sh &&
lunch omni_vee4ss-eng &&
make -j4 recoveryimage
'
```

Output: `/home/builder/out/twrp-4.4/target/product/vee4ss/recovery.img`

## Flash (no fastboot — it's MTK, root required)

The device does not support standard fastboot flashing (same as the E450g,
see [`vee5ss/README.md`](../vee5ss/README.md)). Use `dd` from Android with
root, backing up the current recovery first and verifying by reading back:

```bash
adb push recovery.img /sdcard/recovery_twrp.img
adb shell "su -c 'dd if=/dev/recovery of=/sdcard/recovery_backup_before_twrp.img bs=4096 count=1792; sync'"
adb shell "su -c 'dd if=/sdcard/recovery_twrp.img of=/dev/recovery bs=4096; sync'"
```

Verify (read back and compare against the source image — 6674432 bytes exact
for the current build; read a little extra rounding up to the 4096 block and
limit the comparison to the exact size with `cmp -n` so the rest of the
partition doesn't register as a size mismatch):

```bash
adb shell "su -c 'dd if=/dev/recovery of=/sdcard/recovery_twrp_verify.img bs=4096 count=1630'"
adb pull /sdcard/recovery_twrp_verify.img
cmp -n 6674432 recovery.img recovery_twrp_verify.img && echo "MATCH"
```

```bash
adb reboot recovery
```

## Bootloader

The stock LK bootloader ships with a signature check that blocks unsigned
recovery/CWM/TWRP images ("Security Error"). It was unlocked separately using
the same disassembly-and-patch technique already verified on the E450g's LK
(same signature-check function, recompiled at different offsets) — 9 patches
derived by re-disassembling this device's own `uboot` binary, flashed, and
confirmed to still boot the stock ROM normally afterward. That work is tracked
outside this repo; this device tree assumes the bootloader is already unlocked.
