# Porting Nerves to the Surface RT

How this system is put together, and why. For what's done and what's next,
see [PLAN.md](PLAN.md).

## What's needed

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

## References

- [Nerves docs: Systems](https://hexdocs.pm/nerves/systems.html)
- [`nerves_system_br` README](https://github.com/nerves-project/nerves_system_br) (porting guide)
- [Porting Nerves to the e-RT3](https://dev.to/pojiro/elixir-on-industrial-hardware-porting-nerves-to-e-rt3-7k1),
  an example port to new hardware
- [U-Boot docs: Surface RT](https://docs.u-boot.org/en/latest/board/microsoft/surface-rt.html)
- [Linux Tegra device trees](https://github.com/torvalds/linux/tree/master/arch/arm/boot/dts/nvidia)
