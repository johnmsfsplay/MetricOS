#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SUITE="${SUITE:-trixie}"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/output}"
WORK_DIR="${WORK_DIR:-$SCRIPT_DIR/.metricos-build}"
WITH_CHROME="${WITH_CHROME:-1}"
WITH_INSTALLER="${WITH_INSTALLER:-1}"
MIN_FREE_GB="${MIN_FREE_GB:-25}"

fail(){ echo "MetricOS build error: $*" >&2; exit 1; }
[[ "$(id -u)" -eq 0 ]] || fail "Run with sudo: sudo ./build-iso.sh"
[[ "$(uname -m)" == x86_64 ]] || fail "This build profile targets amd64/x86_64 hosts."
command -v apt-get >/dev/null 2>&1 || fail "This script requires Debian/Ubuntu or Linux Mint with apt-get."
[[ "$WITH_CHROME" == 0 || "$WITH_CHROME" == 1 ]] || fail "WITH_CHROME must be 0 or 1."
[[ "$WITH_INSTALLER" == 0 || "$WITH_INSTALLER" == 1 ]] || fail "WITH_INSTALLER must be 0 or 1."
[[ "$MIN_FREE_GB" =~ ^[0-9]+$ ]] || fail "MIN_FREE_GB must be a non-negative integer."
[[ "$SUITE" =~ ^[a-z][a-z0-9-]+$ ]] || fail "Invalid Debian suite name: $SUITE"
WORK_DIR="$(realpath -m -- "$WORK_DIR")"
OUTPUT_DIR="$(realpath -m -- "$OUTPUT_DIR")"
[[ "$WORK_DIR" == "$SCRIPT_DIR/"* && "$WORK_DIR" != "$SCRIPT_DIR" ]] || fail "WORK_DIR must be a child of the project directory."
[[ "$OUTPUT_DIR" == "$SCRIPT_DIR/"* && "$OUTPUT_DIR" != "$SCRIPT_DIR" ]] || fail "OUTPUT_DIR must be a child of the project directory."
mkdir -p "$OUTPUT_DIR"
FREE_KB="$(df -Pk "$SCRIPT_DIR" | awk 'END {print $4}')"
FREE_GB=$((FREE_KB / 1024 / 1024))
[[ "$FREE_GB" -ge "$MIN_FREE_GB" ]] || fail "Only ${FREE_GB} GiB is free; need at least ${MIN_FREE_GB} GiB. Free disk space and retry."

# Check that the Debian mirror can resolve before modifying the build tree.
getent hosts deb.debian.org >/dev/null 2>&1 || fail "No DNS/network access to deb.debian.org. Connect to the internet and retry."

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y live-build debootstrap xorriso squashfs-tools ca-certificates curl gnupg
for x in lb xorriso debootstrap; do
  command -v "$x" >/dev/null 2>&1 || fail "Dependency installation completed but $x is still unavailable."
done

# Start clean without allowing arbitrary path deletion.
if [[ -e "$WORK_DIR" ]]; then
  [[ -d "$WORK_DIR" && ! -L "$WORK_DIR" ]] || fail "WORK_DIR is not a normal directory."
  rm -rf -- "$WORK_DIR"
fi
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

LB_INSTALLER=none
[[ "$WITH_INSTALLER" == 1 ]] && LB_INSTALLER=live

lb config \
  --distribution "$SUITE" \
  --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --debian-installer "$LB_INSTALLER" \
  --firmware-binary true \
  --firmware-chroot true \
  --apt-secure true \
  --apt-recommends true \
  --updates true \
  --security true \
  --checksums sha256 \
  --image-name metricos-1.0-amd64 \
  --iso-volume METRICOS_1_0 \
  --iso-application "MetricOS 1.0 Live System" \
  --iso-publisher "MetricOS Project" \
  --bootappend-live "boot=live components username=metricos locales=en_US.UTF-8 keyboard-layouts=us quiet splash" \
  --bootappend-live-failsafe "boot=live components username=metricos locales=en_US.UTF-8 keyboard-layouts=us nomodeset" \
  --uefi-secure-boot auto

cp -a "$SCRIPT_DIR/config/." "$WORK_DIR/config/"
if [[ "$WITH_CHROME" != 1 ]]; then
  rm -f "$WORK_DIR/config/hooks/normal/0900-google-chrome.hook.chroot"
  echo "Google Chrome build hook disabled (WITH_CHROME=0). Firefox ESR remains included."
fi

LOG="$OUTPUT_DIR/metricos-build.log"
echo "Building MetricOS for Debian $SUITE (amd64). This may take a long time and several GB of downloads."
set +e
lb build 2>&1 | tee "$LOG"
status=${PIPESTATUS[0]}
set -e
[[ "$status" -eq 0 ]] || fail "live-build failed with status $status. Read $LOG."

ISO_FILE="$(find "$WORK_DIR" -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$ISO_FILE" && -s "$ISO_FILE" ]] || fail "Build finished but no non-empty ISO was found. See $LOG."
DEST="$OUTPUT_DIR/metricos-1.0-amd64.iso"
cp -- "$ISO_FILE" "$DEST"
REL_DEST="$(realpath --relative-to="$SCRIPT_DIR" -- "$DEST")"
(cd "$SCRIPT_DIR" && sha256sum "$REL_DEST") > "$DEST.sha256"
{
  echo "MetricOS 1.0 amd64 ISO"
  echo "Debian suite: $SUITE"
  echo "Build date UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "ISO size: $(du -h "$DEST" | awk '{print $1}')"
  cat "$DEST.sha256"
} > "$OUTPUT_DIR/BUILD-INFO.txt"

echo "ISO created: $DEST"
echo "Checksum: $DEST.sha256"
echo "Next: run ./verify-iso.sh '$DEST' and boot it in a VM before installing."
