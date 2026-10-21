#!/bin/sh

set -e

GRUB_EDITENV=$HOST_DIR/bin/grub-editenv

# Create the Grub environment blocks
$GRUB_EDITENV $BINARIES_DIR/grubenv_a create
$GRUB_EDITENV $BINARIES_DIR/grubenv_a set boot=0
$GRUB_EDITENV $BINARIES_DIR/grubenv_a set validated=0
$GRUB_EDITENV $BINARIES_DIR/grubenv_a set booted_once=0

$GRUB_EDITENV $BINARIES_DIR/grubenv_b create
$GRUB_EDITENV $BINARIES_DIR/grubenv_b set boot=1
$GRUB_EDITENV $BINARIES_DIR/grubenv_b set validated=0
$GRUB_EDITENV $BINARIES_DIR/grubenv_b set booted_once=0

cp $BINARIES_DIR/grubenv_a $BINARIES_DIR/grubenv_a_valid
$GRUB_EDITENV $BINARIES_DIR/grubenv_a_valid set booted_once=1
$GRUB_EDITENV $BINARIES_DIR/grubenv_a_valid set validated=1

cp $BINARIES_DIR/grubenv_b $BINARIES_DIR/grubenv_b_valid
$GRUB_EDITENV $BINARIES_DIR/grubenv_b_valid set booted_once=1
$GRUB_EDITENV $BINARIES_DIR/grubenv_b_valid set validated=1

# Kernel arguments, read by grub.cfg from the rootfs being booted, so they
# ship with each firmware update.
#
# cpuidle.off=1 matches the Open Surface RT images. CPU idle doesn't work
# when booted through UEFI.
#
# clk_ignore_unused and pd_ignore_unused keep the clocks and power domains
# that UEFI left on. Without them the screen goes black about 4 seconds
# into the boot, when the kernel turns off what no driver has claimed yet.
#
# loglevel=4 only prints kernel errors on tty1, which is also the IEx
# console. All kernel messages are still in dmesg and RingLogger.
LINUX_ARGS="console=tty1 rootwait loglevel=4 cpuidle.off=1 clk_ignore_unused pd_ignore_unused"
mkdir -p $TARGET_DIR/boot
rm -f $TARGET_DIR/boot/kernel-args.grubenv
$GRUB_EDITENV $TARGET_DIR/boot/kernel-args.grubenv create
$GRUB_EDITENV $TARGET_DIR/boot/kernel-args.grubenv set "linux_args=$LINUX_ARGS"

# Copy everything that's needed to build firmware images over to the
# output directory so that it can be bundled with the system image.
# Buildroot writes GRUB itself to $BINARIES_DIR/efi-part/EFI/BOOT/bootarm.efi.
cp $NERVES_DEFCONFIG_DIR/grub.cfg $BINARIES_DIR

# Create the fwup ops script to handling MicroSD/eMMC operations at runtime
# NOTE: revert.fw is the previous, more limited version of this. ops.fw is
#       backwards compatible.
mkdir -p $TARGET_DIR/usr/share/fwup
NERVES_SYSTEM=$BASE_DIR $HOST_DIR/usr/bin/fwup -c -f $NERVES_DEFCONFIG_DIR/fwup-ops.conf -o $TARGET_DIR/usr/share/fwup/ops.fw
ln -sf ops.fw $TARGET_DIR/usr/share/fwup/revert.fw

# Copy the fwup includes to the images dir
cp -rf $NERVES_DEFCONFIG_DIR/fwup_include $BINARIES_DIR
