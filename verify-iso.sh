#!/usr/bin/env bash
set -Eeuo pipefail
ISO="${1:-$(dirname -- "$0")/output/metricos-1.0-amd64.iso}"
[[ -s "$ISO" ]] || { echo "ISO not found or empty: $ISO" >&2; exit 1; }
command -v xorriso >/dev/null 2>&1 || { echo "Install xorriso to inspect the ISO." >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || exit 1
printf 'SHA-256: '; sha256sum "$ISO"
if [[ -s "$ISO.sha256" ]]; then
  EXPECTED="$(awk 'NR==1 {print $1}' "$ISO.sha256")"
  ACTUAL="$(sha256sum "$ISO" | awk '{print $1}')"
  [[ "$EXPECTED" == "$ACTUAL" ]] || { echo "SHA-256 mismatch: $ISO" >&2; exit 1; }
  echo "Saved checksum: OK"
else
  echo "No adjacent checksum file; hash shown above only."
fi
echo 'ISO9660 / El Torito report:'
xorriso -indev "$ISO" -report_el_torito as_mkisofs 2>&1
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo "QEMU available. Launch with: qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cdrom \"$ISO\" -boot d"
else
  echo "QEMU not installed; install qemu-system-x86 to boot-test this ISO."
fi
