# Installing Nerves on the Surface RT

The Surface must be jailbroken first (see [JAILBREAK.md](JAILBREAK.md)).

The UEFI firmware can't boot from microSD, so Nerves is installed on the
internal eMMC. This erases the eMMC, including Windows.

## First install

The first install currently needs a second, temporary boot setup:

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

## Updates

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

## Untested alternative: install from Raspberry Pi OS

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
