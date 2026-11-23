# MetricOS 1.0 — Debian 13.8 Trixie / KDE Plasma gaming live system

**Performance, under your control.**

This project upgrades the uploaded ForgeOS starter kit into a real Debian Live build configuration. It includes a KDE Plasma desktop, a dark OLED-inspired theme, a custom wallpaper, a floating Plasma panel default, a MetricOS Control Center with **130 system preferences** and **60 Liquid Glass / OLED appearance controls**, Firefox ESR, a Google Chrome installation hook, and gaming utilities.

## What is included

- Debian 13 Trixie `amd64` base and KDE Plasma 6 desktop.
- Live boot image with the Debian Installer live option enabled by default.
- Firefox ESR and Google Chrome Stable (Chrome is obtained from Google's official signed APT repository; the build hook checks the published signing-key fingerprint before installing it).
- GameMode, MangoHud, Lutris, Vulkan tools, OBS Studio, PipeWire and zram-tools. Gamescope is not included in Debian 13 stable packages and is therefore not bundled in the base image.
- MetricOS OLED and Carbon KDE color schemes, original SVG wallpaper, floating bottom panel defaults.
- MetricOS Control Center: 130 regular preferences plus 60 Liquid Glass/OLED settings. User preferences are stored at `~/.config/metricos/settings.json`. The app applies supported native settings (power profile, KDE colour scheme, KWin animation/blur and detected Plasma panel geometry/opacity/visibility); the rest are kept as preferences and are not falsely represented as kernel-level optimizations.
- Steam is optional and can be installed after boot from the desktop shortcut. Its helper enables Debian i386 architecture and installs the Debian `steam-installer` package from signed Debian repositories.

## Build from Windows 11 without installing Ubuntu

You do not need WSL, Ubuntu, Docker, or a Linux installation on your PC. This project includes a GitHub Actions workflow that builds MetricOS on a temporary hosted Linux runner and uploads the ISO as a downloadable artifact.

Follow **[WINDOWS-CLOUD-BUILD.md](WINDOWS-CLOUD-BUILD.md)**. In summary: extract this project, create a GitHub repository, upload the extracted project files (including the hidden `.github` folder), open **Actions → Build MetricOS ISO → Run workflow**, then download the `MetricOS-1.0-amd64-ISO` artifact after the run succeeds.

The workflow performs the source tests, attempts to reclaim disk space on the temporary runner, builds the image, checks its ISO9660/El Torito structure and SHA-256 digest, and uploads the ISO plus build logs. Standard GitHub-hosted runners have limited disk; the workflow stops clearly if it cannot reclaim at least 27 GiB. It does not install anything on your Windows computer.

## Build requirements

Use a network-connected Debian/Ubuntu/Linux Mint `amd64` computer with root access and at least 25 GB free space. Debian 13.8 Trixie is the current Debian stable point release as of 2026-11-23. The build host must have working DNS/HTTPS access to Debian mirrors; the default build also needs access to Google's Linux package repository for Chrome. A desktop-heavy live ISO may take several GB. The build script installs `live-build`, `debootstrap`, `xorriso`, `squashfs-tools`, `curl`, and `gnupg` on the build host after checking that the Debian mirror resolves. It does not require those tools to be preinstalled.

The official Debian live-build documentation describes this configuration model, package lists, local includes and hooks. See: <https://live-team.pages.debian.net/live-manual/>. Build status and checks performed in the preparation environment are recorded in `BUILD-STATUS.md`.

## Build on Linux Mint

Open a terminal in the extracted `MetricOS-1.0` directory and run:

```bash
chmod +x build-iso.sh verify-iso.sh
sudo ./build-iso.sh
```

Optional flags:

```bash
# Build without Google Chrome if the Google repository is unavailable:
sudo env WITH_CHROME=0 ./build-iso.sh

# Build without the Debian Installer live option:
sudo env WITH_INSTALLER=0 ./build-iso.sh

# Choose another Debian suite only if you know it is supported:
sudo SUITE=trixie ./build-iso.sh
```

Output:

- `output/metricos-1.0-amd64.iso`
- `output/metricos-1.0-amd64.iso.sha256`
- `output/BUILD-INFO.txt`
- `output/metricos-build.log`

## Test before installation

1. Verify the ISO structure and checksum:

   ```bash
   ./verify-iso.sh output/metricos-1.0-amd64.iso
   sha256sum -c output/metricos-1.0-amd64.iso.sha256
   ```

2. Install QEMU if needed, then boot without installing:

   ```bash
   sudo apt install qemu-system-x86 ovmf
   qemu-system-x86_64 -m 4096 -smp 4 -cdrom output/metricos-1.0-amd64.iso -boot d
   ```

3. Test both live boot and the installer in a VM before writing the image to USB or touching your main disk.

## Known boundaries

- This is a community remix built from unchanged Debian packages; it is not an independently developed kernel or graphics driver.
- The UI exposes 190 preferences. Only the documented native mappings change KDE or power profiles; many options are saved preferences for follow-up integrations. Do not infer that every preference applies a driver or kernel change.
- Liquid Glass is implemented through KDE translucency/blur, panel opacity, color scheme and theme controls. It is not an Apple macOS clone and blur support depends on GPU/compositor capabilities.
- Chrome is a proprietary third-party package distributed by Google. The installer verifies Google's primary package-signing key fingerprint and keeps APT signature verification enabled.
- Steam is opt-in; compatibility varies by GPU, driver, game, kernel and Proton version.
- This build kit does not certify the resulting ISO as malware-free. It uses authenticated APT repositories and includes reproducible checksum output; test the actual ISO in a disposable VM and scan it independently if required.

## Safety

The build script checks that build/output directories stay inside the project directory, checks DNS before starting and does not write to physical disks. The resulting ISO is intended for VM testing first. Do not use an installer to repartition a real disk unless you have backed up your data and deliberately selected the correct target.
