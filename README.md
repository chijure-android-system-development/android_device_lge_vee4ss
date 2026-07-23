# TWRP device tree - LG Optimus L4 II

**Device**: LG-E440g
**Codename**: vee4ss
**SoC**: MediaTek MT6575
**CPU**: ARM Cortex-A9
**Android base**: 4.1.2 (JZO54K)
**Stock product**: `lge/vee4ss_sca_com_g/vee4ss`

**Status: confirmed working on real hardware (2026-07-23).** Boots clean, touch
responsive, internal/external storage mounted, MTP working, ADB reliable across
repeated reboot cycles.

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
