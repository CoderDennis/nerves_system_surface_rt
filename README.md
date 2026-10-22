# nerves_system_surface_rt

A [Nerves](https://nerves-project.org/) system for the original Microsoft
Surface RT (2012, NVIDIA Tegra 3).

> **Status:** Nerves runs from the internal eMMC and boots through GRUB,
> with A/B firmware updates over Wi-Fi (`mix upload`) that fall back if
> new firmware doesn't validate. All four CPU cores and the 1 MB L2 cache
> are on. The console is on the built-in screen, with the Touch/Type Cover
> or a USB keyboard. The touchscreen (multitouch), speakers, battery
> status and USB storage work.
> As far as we know, nobody has run Nerves on a Surface RT before.

## Hardware

| Item      | Details                                                        |
| --------- | -------------------------------------------------------------- |
| SoC       | NVIDIA Tegra 3 (T30), 4× Cortex-A9 (ARMv7-A, NEON)             |
| RAM       | 2 GB                                                           |
| Storage   | 32/64 GB internal eMMC, microSD slot                           |
| Wi-Fi/BT  | Marvell 88W8797 (SDIO, Linux driver `mwifiex_sdio`)            |
| USB       | 1× USB 2.0 Type-A, host only (no gadget/OTG)                   |
| Input     | Touchscreen (Atmel maXTouch, HID over I2C), Touch/Type Cover   |
| Firmware  | UEFI with Secure Boot locked on (must be jailbroken, see below) |

This targets the **Surface RT** only. The Surface 2 uses a Tegra 4 and
boots Linux differently.

## Part 1: Jailbreak the Surface RT

The Surface RT only boots Microsoft-signed code. Two exploits get around
this. They're steps of the same jailbreak, and they're done in this order:

1. **Golden Keys** (Secure Boot Debug Policy, CVE-2016-3287 / CVE-2016-3320).
   A leaked Microsoft-signed debug policy that turns on test signing in the
   Windows boot manager. Windows updates from November 2016 onwards block it
   (MS16-094, MS16-100, MS16-140). A device with those updates must be reset
   to an older Windows image first.
2. **Yahallo** (2020, Bingxing Wang, GPLv2). Exploits the Tegra 3/4 UEFI
   variable services to take over TrustZone, then permanently turns off
   Secure Boot. It needs Golden Keys installed first. Microsoft and NVIDIA
   declined to fix it. `YahalloUndo.efi` reverses it.

After Yahallo, the UEFI firmware boots any EFI binary, which is what lets
Linux boot.

### Before you start

- **Back up or give up the data on the device.** Disabling Secure Boot can
  lock out the firmware TPM, which makes BitLocker-encrypted data unreadable.
  Either turn off device encryption from Windows (`manage-bde -off C:`) or
  save the recovery key (`manage-bde -protectors -get C:`, or
  <https://account.microsoft.com/devices/recoverykey>).
- **Don't install Windows updates** before jailbreaking. Use a local
  account, stay off Wi-Fi, or apply `WindowsUpdateManualMode.reg` from the
  jailbreak USB.
- **Keep the tablet plugged in.**
- **Only flash firmware that matches your device.** The jailbreak USB holds
  firmware for several models.

### Resetting the device (if needed)

If Windows has post-2016 updates, or you can't sign in, reset the tablet
with a Windows RT 8.0 recovery image. Microsoft no longer offers one for the
Surface RT at <https://support.microsoft.com/surface-recovery-image>. Use the
community images listed on the Open Surface RT
[Recovery Images](https://open-rt.gitbook.io/open-surfacert/common/windows-rt/recovery-images)
page. Some of the links there are dead. These images are unofficial.

To make the recovery USB on macOS:

```sh
diskutil list external physical          # find the USB drive, e.g. /dev/disk4
diskutil eraseDisk FAT32 RECOVERY MBRFormat /dev/diskN
unzip -q "Surface RT 8.0 North America.zip" -d /Volumes/RECOVERY
```

`sources/Install.wim` is about 3.6 GB, under FAT32's 4 GB per-file limit.
Boot from it with **Volume Down + Power**, then choose
**Troubleshoot → Reset your PC**.

### Making the jailbreak USB on macOS

The jailbreak USB package (`Tegra_Jailbreak_USB.zip`) comes from the
[jwa4 guide](https://jwa4.gitbook.io/).

```sh
diskutil list external physical          # double-check the disk identifier!
diskutil eraseDisk FAT32 SURFACE MBRFormat /dev/diskN
mkdir jailbreak_usb && unzip -q Tegra_Jailbreak_USB.zip -d jailbreak_usb
COPYFILE_DISABLE=1 cp -R jailbreak_usb/ /Volumes/SURFACE/
dot_clean -m /Volumes/SURFACE            # remove macOS ._ metadata files
diskutil eject /dev/diskN
```

`eraseDisk` erases the whole disk without asking for confirmation.

What's on the USB drive:

| Path                                   | Purpose                                   |
| -------------------------------------- | ----------------------------------------- |
| `efi/boot/bootarm.efi`, `efi/microsoft/boot/bcd` | Windows boot manager the Surface boots from |
| `Jailbreak_USB_Menu.cmd`               | Menu for running the jailbreak            |
| `SecureBootDebugPolicy.p7b`, `Jailbreak/SecureBootDebugPolicy/` | Golden Keys |
| `Jailbreak/Yahallo/`                   | `Yahallo.efi`, `YahalloUndo.efi`, README  |
| `Firmware/`                            | UEFI firmware for Surface RT, Surface 2, TF600T, SKU1 |

Boot from USB with **Volume Down + Power**. Let go of Volume Down when the
Surface logo appears. Then follow the
[jwa4 guide](https://jwa4.gitbook.io/), which replaced the Open Surface RT
jailbreak USB page.

### Jailbreak references

- [Open Surface RT guide](https://open-rt.gitbook.io/open-surfacert/)
- [Open Surface RT: Jailbreak Exploits](https://open-rt.gitbook.io/open-surfacert/common/windows-rt/jailbreak-exploits)
- [Open Surface RT: Yahallo, Disable Secure Boot](https://open-rt.gitbook.io/open-surfacert/common/boot-sequence/uefi/secure-boot/disable-secureboot)
- [Open Surface RT: Recovery Images](https://open-rt.gitbook.io/open-surfacert/common/windows-rt/recovery-images)
- [jwa4 guide](https://jwa4.gitbook.io/) (current jailbreak USB instructions)
- [Ubuntu wiki: ARM/SurfaceRT](https://wiki.ubuntu.com/ARM/SurfaceRT)
- Open Surface RT Discord: <https://discord.gg/VW75GmWa95>

## Part 2: Porting Nerves

### What's needed

1. **Nerves system.** Build on
   [`nerves_system_br`](https://github.com/nerves-project/nerves_system_br),
   using an existing ARMv7 system as a template. The Cortex-A9 works with the
   existing `nerves_toolchain_armv7_nerves_linux_gnueabihf` toolchain.
2. **Kernel and device tree.** The Surface RT device tree is **not** in
   mainline Linux. This system builds Linux 6.18.36 with a patch that adds
   it, ported from the Open Surface RT community kernel. See
   [`dts/README.md`](dts/README.md) for the source, the changes and the
   known limitations (one CPU speed). The battery and
   audio drivers are backported from later kernels (`linux/0008`-`0010`).
   The kernel config is `tegra_defconfig` plus
   [`linux/surface-rt.fragment`](linux/surface-rt.fragment).
3. **Bootloader.** After Yahallo, UEFI boots EFI binaries directly. Use
   **GRUB (arm-efi)** for A/B switching, following the GRUB + grubenv pattern
   in [`nerves_system_x86_64`](https://github.com/nerves-project/nerves_system_x86_64).
   Avoid U-Boot: it supports the Surface RT, but has to be loaded over USB
   from another computer (APX/RCM mode) on every boot and only uses one core.
4. **`fwup` config.** Partition layout: EFI FAT boot partition, rootfs A,
   rootfs B, application data. Develop on microSD first, then move to the eMMC.
5. **Development access.** The USB port is host-only, so Nerves' USB gadget
   networking won't work. Use Wi-Fi (VintageNet) or a USB Ethernet adapter,
   with `nerves_ssh` and `mix upload`.
6. **Display (optional).** Nerves runs headless by default. Options are a
   framebuffer console, Scenic on DRM, or a kiosk browser (heavier).

### Using the system

Add it to a Nerves project's `mix.exs` with a target named `surface_rt`:

```elixir
{:nerves_system_surface_rt,
 github: "CoderDennis/nerves_system_surface_rt",
 tag: "v0.2.0",
 runtime: false,
 targets: :surface_rt}
```

Releases have a prebuilt system artifact, so `mix firmware` doesn't need to
build the system. Without one it's built from source, as below.
[nerves_surface_rt_hello](https://github.com/CoderDennis/nerves_surface_rt_hello)
is an example app.

### Building

The system uses `nerves_system_br` 1.35.2, which builds Erlang/OTP 29.1.2
for the target. The host's OTP major version must match, so this repo pins
Erlang 29.1.2 and Elixir 1.20.4-otp-29 in `.tool-versions`.

Don't go below OTP 29.1.1 on the target. Its SSH daemon (ssh 6.0.5)
rejects subsystem requests that follow an `env` request, and macOS's ssh
sends `LANG` and `LC_*` by default, so `mix upload` and `sftp` fail with
"subsystem request failed on channel 0".

```sh
mix archive.install hex nerves_bootstrap
mix deps.get
mix compile        # on macOS, Buildroot runs in Docker (Docker must be running)
```

If your shell doesn't switch versions automatically, prefix the commands
with `mise exec --` (or the `asdf` equivalent).

Nerves writes the Buildroot output to `build.log` in this directory. Don't
redirect `mix compile` to that same file, or the two outputs overwrite
each other. The built system ends up in
`~/.nerves/artifacts/nerves_system_surface_rt-portable-<version>/`.

### Plan

- [x] Finish the jailbreak (Golden Keys, then Yahallo)
- [x] Boot an existing community Surface RT Linux image to confirm the
      kernel, device tree and boot path work
- [x] Nerves system skeleton with `nerves_system_br`, GRUB (arm-efi) and a
      `fwup` config with A/B updates (fwup configs tested with placeholder
      files; full build not run yet)
- [x] Surface RT device tree ported to Linux 6.18 (compiles with `dtc`)
- [x] Full system build (`mix compile`): kernel with EFI stub, Surface RT
      DTB, GRUB `bootarm.efi`, rootfs and a firmware image all build
- [x] Boot Nerves to an IEx prompt (kernel and DTB loaded from the UEFI
      Shell on a USB stick, root filesystem on microSD)
- [x] Boot through GRUB from the eMMC, with A/B updates. The UEFI firmware
      can't see the microSD slot, so Nerves can't boot from microSD.
- [x] Wi-Fi with VintageNet and SSH access
- [x] Display output (Tegra DRM console on the built-in screen)
- [x] Install to eMMC (see [Installing](#installing))
- [ ] An easier first install (today it needs a second, temporary boot
      setup, see below). Now that USB flash drives work, Nerves could
      probably run from a USB stick instead of the microSD card, possibly
      just `mix burn` to a stick and boot it with Volume Down + Power. The
      stick has the same partition IDs as the eMMC install, so it would have
      to come out afterwards. Not tried yet.
- [x] Fall back to the previous firmware if new firmware isn't validated
- [x] Use all four CPU cores (ACPI parking protocol, see `linux/0005`)
- [x] Turn on the L2 cache (through the secure monitor, see `linux/0006`)
- [x] USB flash drives (fixes a mainline ChipIdea bug on Tegra, see
      `linux/0007`)
- [x] Battery status and audio (drivers backported from Linux 7.x)
- [x] Touch/Type Cover, with hotplug (`linux/0011`, `linux/0012`)
- [x] Touchscreen (multitouch, HID over I2C)
- [x] Audio playback through the speakers (fixes a mainline WM8962 bug,
      see `linux/0013`). The speaker volume starts at 0; turn it up with
      `amixer -c 0 sset Speaker 110`.
- [x] Software reboot (restarts through the PMIC, see
      `linux/0003-mfd-tps65910-Restart-through-the-PMIC.patch`)
- [ ] Research the front and rear cameras. They don't seem to be USB:
      probably camera sensors on the Tegra 3's MIPI CSI interface. Start by
      finding the sensors in the firmware's ACPI tables. The community
      kernels don't support them either.

### Installing

The UEFI firmware can't boot from microSD, so Nerves is installed on the
internal eMMC. This erases the eMMC, including Windows. The first install currently needs a
second, temporary boot setup:

1. `mix burn` the firmware to a microSD card.
2. On a FAT-formatted USB stick, put a UEFI Shell as
   `EFI/BOOT/bootarm.efi`, plus the system's `zImage` and
   `tegra30-microsoft-surface-rt-efi.dtb`, and a `startup.nsh` like:
   ```
   fs0:
   zImage dtb=tegra30-microsoft-surface-rt-efi.dtb root=PARTUUID=04030201-02 rootwait console=tty1 cpuidle.off=1 clk_ignore_unused pd_ignore_unused
   reset -s
   ```
   The Open Surface RT Raspberry Pi OS image's boot partition has such a
   UEFI Shell.
3. Boot the Surface from the stick, with the microSD card in, and connect
   to Wi-Fi with `VintageNetWiFi.quick_configure/2`.
4. Copy the `.fw` to the Surface (`sftp nerves.local`, `put` it in
   `/root`), then write it to the eMMC at the IEx prompt:
   ```elixir
   System.cmd("fwup", ["-a", "-i", "/root/<name>.fw", "-d", "/dev/mmcblk0", "-t", "complete", "-U"])
   ```
   This only writes the eMMC's main area. Its boot partitions, which hold
   the UEFI firmware, are read-only in Linux.
5. Power off, remove the microSD card and the USB stick, and press Power.
   The microSD card uses the same partition IDs, so leave it out.

After that, update with `mix upload`. GRUB switches between partitions A
and B on its own, and the Surface restarts into the new firmware by itself.
New firmware boots once as a trial. Nerves.Runtime's StartupGuard
validates it once all applications have started. If it doesn't, the next
boot falls back to the previous firmware: if new firmware hangs, hold
Power for 10 seconds and turn the Surface back on.

The kernel arguments (`LINUX_ARGS` in `post-build.sh`) are in each root
filesystem, so they ship with `mix upload` and are covered by the
fallback. `mix upload` doesn't update the boot partition's `grub.cfg`,
which only picks the partition and handles the fallback. Only a full
install writes it. When it changes, copy it to `/mnt/boot/EFI/BOOT/` on
the device (remount `/mnt/boot` read-write first).

#### Untested alternative: install from Raspberry Pi OS

This would avoid the microSD card and the hand-made UEFI Shell setup. It
only needs one USB stick, but it hasn't been tried yet.

1. Write the Open Surface RT Raspberry Pi OS image to a USB stick, boot the
   Surface from it (Volume Down + Power) and connect to Wi-Fi. Its kernel
   can use USB storage.
2. On the Mac, turn the `.fw` into a raw disk image:
   ```sh
   fwup -a -i <name>.fw -t complete -d surface.img
   ```
3. Copy `surface.img` to the Surface (e.g. with `scp`) and write it to the
   eMMC: `sudo dd if=surface.img of=/dev/mmcblk0 bs=4M conv=fsync`.
   Check with `lsblk` that `mmcblk0` is the 32/64 GB eMMC first.
4. Power off, remove the USB stick, and press Power.

Written as a raw image, the application data partition probably stays at
the 256 MiB set in `fwup.conf`. fwup can only grow it to fill the disk
when it writes the disk directly. Installing the armhf `fwup` package on
Raspberry Pi OS and running `fwup -a -i <name>.fw -t complete -d
/dev/mmcblk0` there would avoid that.

### Nerves references

- [Nerves docs: Systems](https://hexdocs.pm/nerves/systems.html)
- [`nerves_system_br` README](https://github.com/nerves-project/nerves_system_br) (porting guide)
- [Porting Nerves to the e-RT3](https://dev.to/pojiro/elixir-on-industrial-hardware-porting-nerves-to-e-rt3-7k1),
  an example port to new hardware
- [U-Boot docs: Surface RT](https://docs.u-boot.org/en/latest/board/microsoft/surface-rt.html)
- [Linux Tegra device trees](https://github.com/torvalds/linux/tree/master/arch/arm/boot/dts/nvidia)

## License

This project follows the [REUSE](https://reuse.software/) specification.
`REUSE.toml` maps each file to its license, and the license texts are in
`LICENSES/`. Like the official Nerves systems:

| Files | License |
|---|---|
| `linux/` (kernel config fragment and Surface RT device tree patch) | GPL-2.0-only |
| `Config.in`, `nerves_defconfig`, `post-build.sh`, `post-createfs.sh` (Buildroot derived) | GPL-2.0-or-later |
| `fwup.conf`, `fwup-ops.conf`, `fwup_include/`, `grub.cfg`, `rootfs_overlay/`, `mix.exs` and other small config files | CC0-1.0 |
| `README.md`, `dts/README.md` | CC-BY-4.0 |

The device tree comes from the
[Open Surface RT](https://open-rt.gitbook.io/open-surfacert/) community kernel
and keeps its upstream SPDX headers.
