# nerves_system_surface_rt

A [Nerves](https://nerves-project.org/) system for the original [Microsoft
Surface RT](https://en.wikipedia.org/wiki/Surface_(2012_tablet)) (2012, NVIDIA
Tegra 3).

> **Status:** Nerves runs from the internal eMMC and boots through GRUB,
> with A/B firmware updates over Wi-Fi (`mix upload`) that fall back if
> new firmware doesn't validate. All four CPU cores and the 1 MB L2 cache
> are on. The console is on the built-in screen, with the Touch/Type Cover
> or a USB keyboard. The touchscreen (multitouch), speakers, battery
> status and USB storage work.
> As far as we know, nobody has run Nerves on a Surface RT before.

## Hardware

| Item      | Details                                                        |
| --------- | -------------------------------------------------------------- |
| SoC       | NVIDIA Tegra 3 (T30), 4× Cortex-A9 (ARMv7-A, NEON)             |
| RAM       | 2 GB                                                           |
| Storage   | 32/64 GB internal eMMC, microSD slot                           |
| Wi-Fi/BT  | Marvell 88W8797 (SDIO, Linux driver `mwifiex_sdio`)            |
| USB       | 1× USB 2.0 Type-A, host only (no gadget/OTG)                   |
| Input     | Touchscreen (Atmel maXTouch, HID over I2C), Touch/Type Cover   |
| Firmware  | UEFI with Secure Boot locked on (must be jailbroken)           |

This targets the **Surface RT** only. The Surface 2 uses a Tegra 4 and
boots Linux differently.

## Getting started

1. **Jailbreak the Surface**, so it boots unsigned code: see
   [JAILBREAK.md](JAILBREAK.md).
2. **Install Nerves on the eMMC**, then update it with `mix upload`: see
   [INSTALLING.md](INSTALLING.md).

## Using the system

The system is on [Hex](https://hex.pm/packages/nerves_system_surface_rt).
Add it to a Nerves project's `mix.exs` with a target named `surface_rt`:

```elixir
{:nerves_system_surface_rt, "~> 0.2.1", runtime: false, targets: :surface_rt}
```

Releases have a prebuilt system artifact, so `mix firmware` doesn't need to
build the system. Without one it's built from source, as below.
[nerves_surface_rt_hello](https://github.com/CoderDennis/nerves_surface_rt_hello)
is an example app.

## Building

The system uses `nerves_system_br` 1.35.2, which builds Erlang/OTP 29.1.2
for the target. The host's OTP major version must match, so this repo pins
Erlang 29.1.2 and Elixir 1.20.4-otp-29 in `.tool-versions`.

Don't go below OTP 29.1.1 on the target. Its SSH daemon (ssh 6.0.5)
rejects subsystem requests that follow an `env` request, and macOS's ssh
sends `LANG` and `LC_*` by default, so `mix upload` and `sftp` fail with
"subsystem request failed on channel 0".

```sh
mix archive.install hex nerves_bootstrap
mix deps.get
mix compile        # on macOS, Buildroot runs in Docker (Docker must be running)
```

If your shell doesn't switch versions automatically, prefix the commands
with `mise exec --` (or the `asdf` equivalent).

Nerves writes the Buildroot output to `build.log` in this directory. Don't
redirect `mix compile` to that same file, or the two outputs overwrite
each other. The built system ends up in
`~/.nerves/artifacts/nerves_system_surface_rt-portable-<version>/`.

## More documentation

- [PORTING.md](PORTING.md): how the system is put together (kernel,
  bootloader, partitions), with Nerves porting references
- [PLAN.md](PLAN.md): what's done and what's next
- [dts/README.md](dts/README.md): the Surface RT device tree and its
  changes for mainline Linux
- [CHANGELOG.md](CHANGELOG.md)

## License

This project follows the [REUSE](https://reuse.software/) specification.
`REUSE.toml` maps each file to its license, and the license texts are in
`LICENSES/`. Like the official Nerves systems:

| Files | License |
|---|---|
| `linux/` (kernel config fragment and kernel patches) | GPL-2.0-only |
| `Config.in`, `nerves_defconfig`, `post-build.sh`, `post-createfs.sh` (Buildroot derived) | GPL-2.0-or-later |
| `fwup.conf`, `fwup-ops.conf`, `fwup_include/`, `grub.cfg`, `rootfs_overlay/`, `mix.exs` and other small config files | CC0-1.0 |
| `README.md`, `INSTALLING.md`, `JAILBREAK.md`, `PLAN.md`, `PORTING.md`, `dts/README.md` | CC-BY-4.0 |

The device tree comes from the
[Open Surface RT](https://open-rt.gitbook.io/open-surfacert/) community kernel
and keeps its upstream SPDX headers.
