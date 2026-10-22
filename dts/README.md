# Surface RT device tree

The Surface RT device tree isn't in mainline Linux. This system adds it to
the kernel with
[`linux/0001-ARM-tegra-Add-Microsoft-Surface-RT-device-tree.patch`](../linux/0001-ARM-tegra-Add-Microsoft-Surface-RT-device-tree.patch),
which `nerves_defconfig` applies through `BR2_LINUX_KERNEL_PATCH`.

## Source

From the Open Surface RT community kernel,
[Open-Surface-RT/grate-linux](https://github.com/Open-Surface-RT/grate-linux),
`master` branch, commit `25a5100` (Linux 5.17-rc4, Feb 2022):

- `tegra30-microsoft-surface-rt.dts`: the full device.
- `tegra30-microsoft-surface-rt-efi.dts`: includes the above and disables
  what doesn't work when booted through UEFI: the PMIC core regulator, CPU
  DVFS and CPU idle. Upstream it also disables the L2 cache, which this
  system turns back on. This is the one GRUB loads.

The newer `microsoft-surface-rt` branch (Mar 2024) adds memory timings,
thermal zones, L2 cache and working PMIC/DVFS. Its `-efi.dts` is incomplete
(it doesn't include the main `.dts`), so it isn't used here yet.

## Changes for mainline (Linux 6.18.36)

- `mmc` aliases use node paths, since mainline `tegra30.dtsi` has no
  `sdmmcN` labels.
- The Touch/Type Cover's parent I2C bus is referenced by path, since
  mainline `tegra30.dtsi` has no `i2c1` label. The cover needs the
  community kernel's `i2c-hotplug-gpio` driver (`linux/0011`) and its
  exception for I2C address 0x00 (`linux/0012`), neither of which is in
  mainline.
- The `-efi` variant defines the `vdd_pd_core_stub` regulator itself, since
  mainline `tegra30.dtsi` doesn't have it.
- The `-efi` variant describes each CPU's ACPI parking protocol mailbox
  (`microsoft,parking-protocol-mailbox`), from the firmware's ACPI MADT.
  UEFI parks the secondary CPUs there, the way Windows expects, and the
  reset vector can't be changed from the non-secure world.
  `linux/0005` starts them through the mailboxes. Without it, only one of
  the four cores runs.
- The `-efi` variant registers the secure monitor with a
  `trusted-foundations` node and the community's `tlm,microsoft-surface-rt`
  property (supported by `linux/0004`), and keeps the L2 cache, which the
  kernel enables through the monitor (`linux/0006`).
- The `-efi` variant drops the memory controller resets from the `td2`
  (3D2), `vdec` and `venc` powergates. UEFI leaves them powered off, and
  at probe the PMC driver asserts their resets, which first flushes their
  memory clients. On the unpowered hardware that flush times out
  (`failed to flush 3D2 DMA`), the PMC probe fails with `-EBUSY`, and the
  SD card, USB, Wi-Fi and backlight never probe. Only `td2` has been seen
  to fail. `vdec` and `venc` are changed the same way to be safe.

Both files compile with `dtc` against Linux 6.18.36. The 5 warnings come
from the shared Tegra 3 `.dtsi` files; mainline's `tegra30-asus-tf700t`
gives the same 5.

## Known limitations

- **One CPU speed, no CPU idle.** DVFS and CPU idle are disabled in the
  `-efi` variant. UEFI leaves the CPU at its top speed, 1.3 GHz, and idle
  cores still wait in WFI. Deeper idle (LP2) would power cores off and
  bring them back through the CPU reset vector, which can't be changed
  under UEFI.

The device tree declares 1 GB of RAM because 2 GB "doesn't work atm",
according to its comment. That doesn't matter when booting through UEFI:
the kernel takes its memory map from UEFI, not the device tree. The
Raspberry Pi OS image uses the same 1 GB device tree and sees all 2 GB.

## Boot messages

These show up on every boot.

Expected, from what the `-efi` variant and the boot options turn off:

- `tps65910-pmic ... probe ... failed with error -22`: the PMIC's
  regulators are removed.
- `tegra20-cpufreq: operating points not found`: the CPU operating points
  are removed.
- `failed to register cpuidle driver`: `cpuidle.off=1`.

Not looked into yet:

- `serial-tegra 70006200.serial: Couldn't get the reset`.
- `spi-nor spi0.1: unrecognized JEDEC id bytes: 00 00 00 00 00 00`: the
  SPI flash in the device tree doesn't answer.
- `tegra-mc ... display0a: read @0x...: EMEM address decode error`, once,
  probably during the handover from the UEFI framebuffer.
- `null-device:pll_p_out3_cclkg: connection ID is greater than 16` and
  similar, from the Tegra 3 clock driver at time 0.

## TODO

- Try the 2024 branch's improvements (DVFS, memory timings, thermal zones).
