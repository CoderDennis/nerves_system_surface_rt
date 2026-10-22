# Plan

What's done and what's next for
[nerves_system_surface_rt](README.md).

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
- [x] Install to eMMC (see [Installing](README.md#installing))
- [ ] An easier first install (today it needs a second, temporary boot
      setup, see [Installing](README.md#installing)). Now that USB flash
      drives work, Nerves could probably run from a USB stick instead of
      the microSD card, possibly just `mix burn` to a stick and boot it with
      Volume Down + Power. The stick has the same partition IDs as the eMMC
      install, so it would have to come out afterwards. Not tried yet.
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
- [x] Hardware watchdog: the PMIC's watchdog power-cycles the Surface if
      the system hangs (`linux/0014`). The Tegra watchdog's reset doesn't
      bring it back.
- [ ] Research the front and rear cameras. They don't seem to be USB:
      probably camera sensors on the Tegra 3's MIPI CSI interface. Start by
      finding the sensors in the firmware's ACPI tables. The community
      kernels don't support them either.
