# MetricOS 1.0 build status — 2026-11-23

## Result

**The ISO was not produced in this environment.** This directory is the prepared, test-checked live-build project. It must not be represented as a completed or boot-tested ISO.

## Concrete blocker

I ran `./build-iso.sh` from this environment. It stopped before modifying the host or build tree with:

```text
MetricOS build error: No DNS/network access to deb.debian.org. Connect to the internet and retry.
```

The environment also has none of the required image tools installed: `lb`, `xorriso`, `debootstrap`, `mksquashfs`, `grub-mkrescue`, or `qemu-system-x86_64`. APT cannot fetch the required packages because DNS resolution for Debian mirrors fails here. Therefore I cannot download the Debian base packages, compile the ISO, or boot it in a VM in this session.

## Checks completed on the project source

- 10 project unit tests passed.
- Python Control Center source compiles successfully (`py_compile`).
- Build script, ISO verification script, Debian chroot hooks and installed helper scripts pass shell syntax checks.
- Both JSON files parse successfully.
- The custom SVG wallpaper parses as valid XML.
- The settings catalog contains 130 system controls and 60 appearance controls, with unique IDs, valid defaults, ranges and category mappings.
- The build script installs its build tools before checking for them, validates its internal work/output paths, and refuses to proceed without Debian mirror DNS.
- Debian package catalogue checks were used to remove the obsolete `plasma-workspace-wayland` package name. The main `plasma-workspace` package supplies the Plasma workspace in Trixie.

These are source/configuration checks only. They do **not** prove that the complete live-build completes, the desktop boots, all hardware works, the installer works, or the ISO is malware-free.

## Build from Windows without installing Linux

A cloud-build workflow is included at `.github/workflows/build-metricos.yml`. It is configured for manual runs, performs source tests, reclaims unused storage on the disposable GitHub-hosted Ubuntu runner, builds the ISO, verifies its structure and SHA-256, and uploads the ISO plus logs as the `MetricOS-1.0-amd64-ISO` artifact. Windows users should follow `WINDOWS-CLOUD-BUILD.md`.

The workflow has been syntax- and source-checked locally, but it has **not** yet been executed on GitHub. The actual ISO is still not produced until a user triggers a successful cloud workflow. The hosted runner is space-constrained and the workflow fails early if it cannot reclaim at least 27 GiB.

## Build it on a network-connected Linux Mint / Debian machine

From the extracted `MetricOS-1.0` directory:

```bash
chmod +x build-iso.sh verify-iso.sh
sudo ./build-iso.sh
```

If Google's package repository is unavailable and you want to install Chrome after boot instead:

```bash
sudo env WITH_CHROME=0 ./build-iso.sh
```

Expected output path:

```text
output/metricos-1.0-amd64.iso
```

When the build completes, check it:

```bash
./verify-iso.sh output/metricos-1.0-amd64.iso
sha256sum -c output/metricos-1.0-amd64.iso.sha256
```

Then boot it in a disposable VM before installing it on hardware. Example using QEMU:

```bash
qemu-system-x86_64 -m 4096 -smp 4 -cdrom output/metricos-1.0-amd64.iso -boot d
```

Use a separate VM disk for installer testing. Do not select your real computer's disk in an installer until you have backups and have deliberately chosen the correct destination.
