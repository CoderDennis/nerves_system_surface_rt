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
- [x] Install to eMMC (see [INSTALLING.md](INSTALLING.md))
- [ ] An easier first install (today it needs a second, temporary boot
      setup, see [INSTALLING.md](INSTALLING.md)). Now that USB flash
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
- [x] Identify the front and rear cameras. Both are OmniVision OV9726
      sensors (chip ID 0x9726) at address 0x10 on I2C3 (`i2c@7000c500`),
      so only one can be powered at a time. Power sequence from the ACPI
      method `\_SB.GFXC.CAM1.CPWR`: 1.8 V I/O on GPIO BB4, then each
      camera's 2.8 V LDO (R6, R7), then its reset (BB0, BB7, active low).
      The power-down pins are S1 and R4, active high. The sensors only
      answer on I2C with MCLK running: the `vi_sensor` clock (UEFI sets it
      to 24 MHz) and the `csus` gate, on pin `cam_mclk_pcc0` (function
      `vi_alt3`). ACPI also lists address 0x72, but nothing answers there.
- [ ] Camera capture. Work in progress on the `camera` branch: the
      Tegra30 camera interface (VI/CSI, backported from Linux 7.1) and a new
      OV9726 sensor driver, with camera 1 described on CSI-A. The sensor
      probes and streams, but no image data reaches the VI yet, and the
      wedged VI then freezes the Surface. See that branch's PLAN.md for the
      details, and `camera-debug` for the debug patch.
