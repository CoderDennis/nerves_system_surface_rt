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
  DVFS, the L2 cache and CPU idle. This is the one GRUB loads.

The newer `microsoft-surface-rt` branch (Mar 2024) adds memory timings,
thermal zones, L2 cache and working PMIC/DVFS. Its `-efi.dts` is incomplete
(it doesn't include the main `.dts`), so it isn't used here yet.

## Changes for mainline (Linux 6.18.36)

- `mmc` aliases use node paths, since mainline `tegra30.dtsi` has no
  `sdmmcN` labels.
- The Touch/Type Cover node is left out. It needs the community kernel's
  `i2c-hotplug-gpio` driver, which isn't in mainline.
- The `-efi` variant defines the `vdd_pd_core_stub` regulator itself, since
  mainline `tegra30.dtsi` doesn't have it.

Both files compile with `dtc` against Linux 6.18.36. The 5 warnings come
from the shared Tegra 3 `.dtsi` files; mainline's `tegra30-asus-tf700t`
gives the same 5.

## Known limitations

- **No Touch/Type Cover.** Use a USB keyboard.
- **1 GB of RAM.** The device tree declares 1 GB because 2 GB "doesn't work
  atm", according to its comment.
- **One CPU speed, no L2 cache.** Disabled in the `-efi` variant.
- **No battery status or audio.** The drivers for these were added to
  mainline after 6.18.

## TODO

- Port `i2c-hotplug-gpio` for the cover keyboard.
- Try the 2024 branch's improvements (L2 cache, DVFS, memory timings).
- Move to a newer kernel for the battery and audio drivers.
