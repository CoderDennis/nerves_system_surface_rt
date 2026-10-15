# Surface RT device tree

The Surface RT device tree is **not** in mainline Linux. As of this writing,
`arch/arm/boot/dts/nvidia/Makefile` lists other Tegra 3 tablets, such as
`tegra30-asus-tf600t` (VivoTab RT), but no Surface RT.

## TODO

1. Get the Surface RT `.dts` from the Open Surface RT / grate-driver
   community kernel trees. The `-efi` variant is meant for booting through
   UEFI (after Yahallo), and is what `grub.cfg` expects
   (`tegra30-microsoft-surface-rt-efi.dtb`). Check the exact file name in
   the tree you use.
2. Add it to the kernel build. Two options:
   - **Kernel patch (recommended).** Add the `.dts` under
     `arch/arm/boot/dts/nvidia/` and to its `Makefile` in a patch, then set
     `BR2_LINUX_KERNEL_PATCH` and `BR2_LINUX_KERNEL_INTREE_DTS_NAME`.
     Includes like `#include "tegra30.dtsi"` keep working this way.
   - **`BR2_LINUX_KERNEL_CUSTOM_DTS_PATH`.** Buildroot copies the file into
     the top of `arch/arm/boot/dts/`. Because the Tegra files moved into
     `nvidia/` in Linux 6.5, the `.dts` includes probably need adjusting.
3. In `nerves_defconfig`, set `BR2_LINUX_KERNEL_DTS_SUPPORT=y` and one of
   the options above. Buildroot then installs the `.dtb` to `/boot` in the
   root filesystem, where `grub.cfg` loads it with `devicetree`.

## References

- [Linux Tegra device trees](https://github.com/torvalds/linux/tree/master/arch/arm/boot/dts/nvidia)
- [Open Surface RT](https://open-rt.gitbook.io/open-surfacert/)
- [Ubuntu wiki: ARM/SurfaceRT](https://wiki.ubuntu.com/ARM/SurfaceRT)
