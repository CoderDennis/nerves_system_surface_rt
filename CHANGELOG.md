# Changelog

## v0.2.0 - 2026-10-21

The first version that runs on the Surface RT. Nerves installs to the
internal eMMC, boots through GRUB, and updates over Wi-Fi with `mix upload`.

* New features
  * Boot through GRUB (arm-efi) from the eMMC, with A/B updates. New
    firmware boots once as a trial, and GRUB falls back to the previous
    firmware if Nerves.Runtime's StartupGuard doesn't validate it.
  * Kernel arguments are in each root filesystem
    (`/boot/kernel-args.grubenv`), so they ship with firmware updates and
    are covered by the fallback.
  * All four CPU cores, started through the UEFI firmware's ACPI
    multiprocessor parking protocol (`linux/0005`).
  * 1 MB L2 cache, enabled through the Surface RT's secure monitor
    (`linux/0004`, `linux/0006`).
  * Software reboot, through the PMIC (`linux/0003`).
  * Wi-Fi (Marvell 88W8797, `mwifiex`) as `wlan0` (`linux/0002`).
  * Touch/Type Cover with hotplug (`linux/0011`, `linux/0012`).
  * Touchscreen, battery and charger status (`linux/0009`, `linux/0010`),
    speakers (`linux/0008`, `linux/0013`), and USB flash drives
    (`linux/0007`).
  * `alsa-utils` (`amixer`, `aplay`, `speaker-test`).
  * UTF-8 locale, so the Erlang VM no longer falls back to latin1.

* Fixes
  * The PMC probe no longer fails when booting through UEFI. Without it
    the SD card, USB, Wi-Fi and backlight didn't work.
  * `clk_ignore_unused` and `pd_ignore_unused` keep the screen on.
  * Only kernel errors are printed on the IEx console (`loglevel=4`).
  * Nerves.Runtime's StartupGuard no longer reboots the device after 15
    minutes.

* Mainline bugs fixed here
  * `linux/0007`: ChipIdea's Tegra DMA bounce buffer corrupted transfers
    that came with their own DMA mapping, so USB flash drives never
    showed up.
  * `linux/0013`: the WM8962 codec driver turned off SYSCLK while it was
    in use, so the speakers were silent.

* Known limitations
  * The CPU runs at a fixed 1.3 GHz, with no DVFS or deep CPU idle.
  * The first install needs a temporary boot setup (see the README).
  * `mix upload` doesn't update `grub.cfg` on the boot partition.

* Package updates
  * `nerves_system_br` 1.35.2 (Erlang/OTP 29.1.2). OTP 29.1's SSH daemon
    rejected `mix upload` from macOS.
  * Linux 6.18.36 with the Surface RT device tree and the patches above.

## v0.1.0 (unreleased)

* Initial skeleton, based on `nerves_system_x86_64` (GRUB A/B updates) and
  `nerves_system_bbb` (ARMv7 toolchain), using `nerves_system_br` 1.35.0.
  Not built or booted yet.
