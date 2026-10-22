# Jailbreaking the Surface RT

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
Linux boot. Next, see [INSTALLING.md](INSTALLING.md).

## Before you start

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

## Resetting the device (if needed)

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

## Making the jailbreak USB on macOS

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

## References

- [Open Surface RT guide](https://open-rt.gitbook.io/open-surfacert/)
- [Open Surface RT: Jailbreak Exploits](https://open-rt.gitbook.io/open-surfacert/common/windows-rt/jailbreak-exploits)
- [Open Surface RT: Yahallo, Disable Secure Boot](https://open-rt.gitbook.io/open-surfacert/common/boot-sequence/uefi/secure-boot/disable-secureboot)
- [Open Surface RT: Recovery Images](https://open-rt.gitbook.io/open-surfacert/common/windows-rt/recovery-images)
- [jwa4 guide](https://jwa4.gitbook.io/) (current jailbreak USB instructions)
- [Ubuntu wiki: ARM/SurfaceRT](https://wiki.ubuntu.com/ARM/SurfaceRT)
- Open Surface RT Discord: <https://discord.gg/VW75GmWa95>
