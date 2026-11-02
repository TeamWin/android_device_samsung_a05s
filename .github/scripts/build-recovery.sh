#!/usr/bin/env bash
set -eo pipefail

: "${BUILD_ROOT:?BUILD_ROOT must name the source checkout}"
: "${ARTIFACT_DIR:?ARTIFACT_DIR must name the artifact directory}"
: "${DEVICE_TREE:?DEVICE_TREE must name the device tree checkout}"
mkdir -p "$ARTIFACT_DIR"

sync_sources() {
    mkdir -p "$BUILD_ROOT" "$RUNNER_TEMP/a05s-tools"
    curl --fail --location --retry 3 \
        https://storage.googleapis.com/git-repo-downloads/repo \
        --output "$RUNNER_TEMP/a05s-tools/repo"
    chmod +x "$RUNNER_TEMP/a05s-tools/repo"
    export PATH="$RUNNER_TEMP/a05s-tools:$PATH"
    git config --global user.name 'github-actions[bot]'
    git config --global user.email '41898282+github-actions[bot]@users.noreply.github.com'
    cd "$BUILD_ROOT"
    repo init --depth=1 --no-clone-bundle \
        -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git \
        -b twrp-12.1 2>&1 | tee "$ARTIFACT_DIR/repo-init.log"

    local synced=false
    local attempt
    for attempt in 1 2 3; do
        if repo sync --current-branch --no-clone-bundle --no-tags \
            --fail-fast -j4 2>&1 | tee -a "$ARTIFACT_DIR/repo-sync.log"; then
            synced=true
            break
        fi
        echo "Source synchronization attempt $attempt failed." >&2
        sleep 15
    done
    if [[ "$synced" != true ]]; then
        return 1
    fi
    repo manifest -r -o "$ARTIFACT_DIR/resolved-manifest.xml"
    # Preserve an explicit tracking-ID release when the same input frame also
    # reports zero touch-major/pressure (observed on the Himax panel).
    git -C bootable/recovery apply --check \
        "$DEVICE_TREE/.github/patches/preserve-tracking-id-release.patch"
    git -C bootable/recovery apply \
        "$DEVICE_TREE/.github/patches/preserve-tracking-id-release.patch"
    python3 "$DEVICE_TREE/.github/scripts/test-touch-release.py" \
        "$BUILD_ROOT/bootable/recovery/minuitwrp/events.cpp" \
        2>&1 | tee "$ARTIFACT_DIR/touch-release-test.txt"
    mkdir -p device/samsung/a05s
    rsync -a --exclude=.git --exclude=.github \
        "$DEVICE_TREE/" device/samsung/a05s/
    bash -n device/samsung/a05s/vendorsetup.sh

    # The upstream product hook respects this lock. Haptics are disabled in
    # BoardConfig.mk, so do not apply the unrelated JDM source patch in CI.
    mkdir -p .jdm_patch_lock
    python3 - "$BUILD_ROOT/device/samsung/a05s" <<'PY'
from pathlib import Path
import re
import subprocess
import sys

tree = Path(sys.argv[1])
match = re.search(rb"Linux version ([^ ]+)", (tree / "prebuilt/kernel").read_bytes())
if match is None:
    raise SystemExit("Could not identify the prebuilt kernel release")
release = match.group(1).decode()
for name in ["hx83112f.ko", "icnl9922c.ko"]:
    path = tree / "recovery/root/vendor/lib/modules/touch" / name
    vermagic = subprocess.check_output(["modinfo", "-F", "vermagic", str(path)], text=True).strip()
    if vermagic.split()[0] != release:
        raise SystemExit(f"Kernel/module mismatch: {release}: {name}: {vermagic}")
    print(f"{name}: {vermagic}")
print(f"Prebuilt kernel: {release}")
PY
    {
        printf 'Device tree commit: %s\n' "$GITHUB_SHA"
        printf 'Source manifest: twrp-12.1; exact revisions in resolved-manifest.xml\n'
        printf 'Build target: twrp_a05s-eng recoveryimage\n'
        printf 'Kernel: existing prebuilt, no kernel compilation\n'
        printf 'TWRP input: preserve explicit tracking-ID release before zero pressure\n'
        printf 'JDM haptics hook: skipped (TW_NO_HAPTICS=true)\n'
        printf 'Build URL: https://github.com/%s/actions/runs/%s\n' "$GITHUB_REPOSITORY" "$GITHUB_RUN_ID"
    } > "$ARTIFACT_DIR/build-info.txt"
    df -h
}

build_recovery() {
    cd "$BUILD_ROOT"
    export ALLOW_MISSING_DEPENDENCIES=true
    export LC_ALL=C
    export TZ=UTC
    export BUILD_USERNAME=github-actions
    export BUILD_HOSTNAME=github-actions
    export USE_CCACHE=0
    export _JAVA_OPTIONS=-Xmx4096m
    {
        # Android envsetup is sourced intentionally; its functions drive the build.
        # Its vendor scripts use optional probes that may return nonzero.
        set +e
        # shellcheck disable=SC1091
        source build/envsetup.sh
        if ! declare -F lunch >/dev/null || ! declare -F m >/dev/null; then
            printf 'Android envsetup did not define lunch and m.\n' >&2
            return 1
        fi
        lunch twrp_a05s-eng
        local lunch_status=$?
        set -e
        if (( lunch_status != 0 )); then
            return "$lunch_status"
        fi
        m -j2 recoveryimage
    } 2>&1 | tee "$ARTIFACT_DIR/build.log"
}

collect_images() {
    local product="$BUILD_ROOT/out/target/product/a05s"
    local ramdisk="$product/recovery/root"
    local tree="$BUILD_ROOT/device/samsung/a05s"
    test -s "$product/recovery.img"
    test -s "$product/recovery.tar"
    # Check the files actually staged into the recovery ramdisk.
    local relative
    for relative in \
        lib/modules/spi-msm-geni.ko \
        vendor/lib/modules/touch/hx83112f.ko \
        vendor/lib/modules/touch/icnl9922c.ko \
        vendor/lib/modules/touch/modules.dep \
        vendor/lib/modules/touch/modules.load \
        vendor/firmware/hx83112f_TXD_FW.bin \
        vendor/etc/init/init.ravindu644.custom.rc; do
        cmp "$tree/recovery/root/$relative" "$ramdisk/$relative"
    done
    tar -tf "$product/recovery.tar" | grep -Fx recovery.img
    cp "$product/recovery.img" "$product/recovery.tar" "$ARTIFACT_DIR/"
    cd "$ARTIFACT_DIR"
    sha256sum recovery.img recovery.tar > SHA256SUMS
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        {
            printf 'Built recovery.img and recovery.tar for a05s.\n\n'
            printf 'The artifact includes SHA-256 checksums, the build log, and the resolved source manifest.\n\n'
            printf 'Himax, Chipone, SPI modules and TXD firmware were verified in the staged ramdisk.\n'
            printf 'Touch functionality still requires a recovery boot and input-event test.\n'
        } >> "$GITHUB_STEP_SUMMARY"
    fi
}

case "${1:-}" in
    sync) sync_sources ;;
    build) build_recovery ;;
    collect) collect_images ;;
    *) printf 'Usage: %s {sync|build|collect}\n' "$0" >&2; exit 2 ;;
esac
