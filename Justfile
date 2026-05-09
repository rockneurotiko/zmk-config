# ZMK Firmware Build Justfile
# Adapted from urob/zmk-config (nix bits removed, docker-first approach).
#
# Quick start:
#   just init          # one-time: west init + update (inside docker)
#   just build all     # build every target in build.yaml
#   just build left    # build only targets matching "left"
#   just flash left    # copy UF2 to mounted drive
#
# Prerequisites:
#   - just  (https://github.com/casey/just)
#   - docker
#   - yq (python-yq, NOT golang-yq) — only for build/list commands
#
# For native (non-docker) builds, set DOCKER=0:
#   DOCKER=0 just build all
# This requires west, cmake, dtc, and the Zephyr SDK installed locally.

default:
    @just --list --unsorted

config     := absolute_path("config")
build_dir  := absolute_path(".build")
out        := absolute_path("firmware")

# Paths relative to the project root — used inside Docker where the mount
# point (/workspace) differs from the host absolute path.
rel_config    := "/workspace/config"
rel_build_dir := ".build"
rel_zmk_app   := "zmk/app"

build_matrix := "build.yaml"

# Docker image matching the Zephyr version used by our ZMK revision.
# ZMK v0.3 → Zephyr 3.5 → zmk-dev-arm:3.5-branch
docker_image := env("ZMK_DOCKER_IMAGE", "zmkfirmware/zmk-dev-arm:3.5-branch")

# Set DOCKER=0 to use native west/cmake/zephyr-sdk instead of docker.
use_docker := env("DOCKER", "1")

# ── Helpers ────────────────────────────────────────────────────────────────

# Run a command either natively or inside docker, depending on DOCKER env.
[private]
_run +cmd:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{ use_docker }}" == "1" ]]; then
        docker run --rm \
            -v "{{ justfile_directory() }}":/workspace \
            -w /workspace \
            -u "$(id -u):$(id -g)" \
            {{ docker_image }} \
            {{ cmd }}
    else
        {{ cmd }}
    fi

# Parse build.yaml and filter targets by expression.
[private]
_parse_targets expr: _check_yq
    #!/usr/bin/env bash
    attrs="[.board, .shield, .snippet, .\"artifact-name\", .\"cmake-args\"]"
    filter="(($attrs | map(. // [.]) | combinations), ((.include // {})[] | $attrs)) | join(\",\")"
    echo "$(yq -r "$filter" {{ build_matrix }} | grep -v "^," | grep -i "${expr/#all/.*}")"

# Warn if user has golang-yq instead of python-yq.
[private]
[no-exit-message]
_check_yq:
    #!/usr/bin/env bash
    if ! command -v yq &>/dev/null; then
        echo "yq not found. Install python-yq: pipx install yq" >&2
        exit 1
    fi
    if yq --help 2>&1 | grep -qi 'eval'; then
        echo "This Justfile requires python-yq, but PATH contains golang-yq." >&2
        echo "Install python-yq: pipx install yq" >&2
        exit 1
    fi

# ── Init & update ─────────────────────────────────────────────────────────

# Initialize the west workspace (one-time setup).
init:
    just _run sh -c 'west init -l config 2>/dev/null || true'
    just _run west update --fetch-opt=--filter=blob:none
    just _run west zephyr-export

# Update west modules (ZMK, zmk-helpers, etc.) to revisions in west.yml.
update:
    just _run west update --fetch-opt=--filter=blob:none

# ── Build ──────────────────────────────────────────────────────────────────

# Build firmware for a single board+shield combination.
[private]
_build_single board shield snippet artifact cmake_args *west_args:
    #!/usr/bin/env bash
    set -euo pipefail
    board="{{ board }}"
    shield="{{ shield }}"
    snippet="{{ snippet }}"
    artifact="{{ artifact }}"
    cmake_args="{{ cmake_args }}"
    artifact="${artifact:-${shield:+${shield// /+}-}${board//\//_}}"

    echo "━━━ Building $artifact ━━━"

    if [[ "{{ use_docker }}" == "1" ]]; then
        # Inside Docker the workspace is /workspace, not the host path.
        build_path="{{ rel_build_dir }}/$artifact"
        cmd="west zephyr-export >/dev/null 2>&1;"
        cmd+=" west build -s {{ rel_zmk_app }} -d $build_path -b $board {{ west_args }}"
        cmd+=" ${snippet:+-S \"$snippet\"}"
        cmd+=" -- -DZMK_CONFIG={{ rel_config }}"
        cmd+=" -DBOARD_ROOT=/workspace"
        cmd+=" ${shield:+-DSHIELD=\"$shield\"}"
        cmd+=" $cmake_args"

        docker run --rm \
            -v "{{ justfile_directory() }}":/workspace \
            -w /workspace \
            -u "$(id -u):$(id -g)" \
            -e ZEPHYR_BASE=/workspace/zephyr \
            {{ docker_image }} \
            bash -c "$cmd"
    else
        build_path="{{ build_dir }}/$artifact"
        cmd="west build -s zmk/app -d $build_path -b $board {{ west_args }}"
        cmd+=" ${snippet:+-S \"$snippet\"}"
        cmd+=" -- -DZMK_CONFIG={{ config }}"
        cmd+=" ${shield:+-DSHIELD=\"$shield\"}"
        cmd+=" $cmake_args"

        eval "$cmd"
    fi

    # Copy artifacts — use host paths (build_path on host is always under build_dir)
    build_path="{{ build_dir }}/$artifact"
    mkdir -p "{{ out }}"
    if [[ -f "$build_path/zephyr/zmk.uf2" ]]; then
        cp "$build_path/zephyr/zmk.uf2" "{{ out }}/$artifact.uf2"
        echo "  → {{ out }}/$artifact.uf2"
    elif [[ -f "$build_path/zephyr/zmk.bin" ]]; then
        cp "$build_path/zephyr/zmk.bin" "{{ out }}/$artifact.bin"
        echo "  → {{ out }}/$artifact.bin"
    fi

# Build firmware for targets matching a pattern (or "all").
build expr="all" *west_args:
    #!/usr/bin/env bash
    set -euo pipefail
    targets=$(just build_matrix={{ build_matrix }} _parse_targets "{{ expr }}")

    if [[ -z "$targets" ]]; then
        echo "No targets matching '{{ expr }}'. Run 'just list' to see available targets." >&2
        exit 1
    fi

    echo "$targets" | while IFS=, read -r board shield snippet artifact cmake_args; do
        just \
            use_docker={{ use_docker }} \
            docker_image={{ docker_image }} \
            _build_single "$board" "$shield" "$snippet" "$artifact" "$cmake_args" {{ west_args }}
    done

    echo ""
    echo "━━━ Build complete ━━━"
    ls -lh {{ out }}/*.{uf2,bin} 2>/dev/null || true

# ── Flash ──────────────────────────────────────────────────────────────────

# Flash firmware to a board. Waits for the UF2 bootloader drive to appear.
# Usage: just flash left   — flash left half
#        just flash right  — flash right half
#        just flash <pat>  — flash any firmware matching <pat>
flash expr:
    #!/usr/bin/env bash
    set -euo pipefail

    # Find matching firmware file
    shopt -s nullglob
    files=({{ out }}/*"{{ expr }}"*.uf2)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "❌ No firmware matching '{{ expr }}' in {{ out }}/" >&2
        echo "   Build first with: just build {{ expr }}" >&2
        exit 1
    fi
    if [[ ${#files[@]} -gt 1 ]]; then
        echo "⚠ Multiple matches — using first:" >&2
        printf '   %s\n' "${files[@]}" >&2
    fi
    fw="${files[0]}"
    echo "━━━ Flashing $(basename "$fw") ━━━"

    # Helper: find a UF2 bootloader drive (mounted or not).
    # 1) Check already-mounted drives by name.
    # 2) If not found, look for unmounted UF2 block devices and auto-mount.
    find_drive() {
        # Check mounted drives first
        local d
        d=$(find /run/media/"$USER" /media /mnt \
            -maxdepth 2 -type d \
            \( -iname "*nicenano*" -o -iname "*nrf*" -o -iname "*uf2*" \
               -o -iname "*xiao*" -o -iname "*nrf52boot*" \
               -o -iname "*keebart*" \) \
            2>/dev/null | head -1 || true)
        if [[ -n "$d" ]]; then
            echo "$d"
            return
        fi

        # Look for unmounted UF2 block devices via lsblk
        local dev
        dev=$(lsblk -rno NAME,LABEL,FSTYPE,MOUNTPOINT \
            | awk '$3 == "vfat" && $4 == "" && tolower($2) ~ /nicenano|nrf|uf2|xiao|nrf52boot|keebart/ {print "/dev/" $1; exit}' \
            || true)
        if [[ -n "$dev" ]]; then
            echo "🔌 Found unmounted device $dev, mounting…" >&2
            udisksctl mount -b "$dev" --no-user-interaction >&2 2>&1 || true
            sleep 1
            # Re-check mounted drives
            find /run/media/"$USER" /media /mnt \
                -maxdepth 2 -type d \
                \( -iname "*nicenano*" -o -iname "*nrf*" -o -iname "*uf2*" \
                   -o -iname "*xiao*" -o -iname "*nrf52boot*" \
                   -o -iname "*keebart*" \) \
                2>/dev/null | head -1 || true
        fi
    }

    drive=$(find_drive)
    if [[ -z "$drive" ]]; then
        echo "⏳ Waiting for UF2 drive… double-tap the reset button now."
        timeout=60
        elapsed=0
        while [[ -z "$drive" && $elapsed -lt $timeout ]]; do
            sleep 1
            ((elapsed++)) || true
            drive=$(find_drive)
        done
    fi

    if [[ -z "$drive" ]]; then
        echo "❌ Timed out (${timeout}s). No bootloader drive found." >&2
        echo "   Copy manually:  cp $fw /path/to/drive/" >&2
        exit 1
    fi

    echo "📁 Found drive: $drive"
    cp "$fw" "$drive/"
    echo "✅ Copied! Board will reset automatically."
    # Wait a beat so the user sees the message before the drive unmounts
    sleep 1

# ── List & info ────────────────────────────────────────────────────────────

# List all build targets from build.yaml.
list:
    @just build_matrix={{ build_matrix }} _parse_targets all \
        | sed 's|[@/][^,]*,|,|' \
        | awk -F, '{ print ($2 != "" ? $2 " (" $1 ")" : $1) }' \
        | sort \
        | column

# Show build matrix in full detail.
matrix:
    @just build_matrix={{ build_matrix }} _parse_targets all \
        | column -t -s,

# ── Keymap drawing ─────────────────────────────────────────────────────────

draw_config := "draw/config.yaml"
draw_dir    := "draw"

# Parse and draw the keymap to SVG. Requires keymap-drawer (pipx install keymap-drawer).
draw: _check_keymap_drawer
    #!/usr/bin/env bash
    set -euo pipefail
    keymap -c "{{ draw_config }}" parse -z config/base.keymap \
        --virtual-layers Combos > "{{ draw_dir }}/base.yaml"
    keymap -c "{{ draw_config }}" draw "{{ draw_dir }}/base.yaml" \
        --ortho-layout '{"split": true, "rows": 3, "columns": 5, "thumbs": 3}' \
        -o "{{ draw_dir }}/base.svg"
    echo "━━━ Keymap drawn to {{ draw_dir }}/base.svg ━━━"

[private]
[no-exit-message]
_check_keymap_drawer:
    #!/usr/bin/env bash
    if ! command -v keymap &>/dev/null; then
        echo "keymap-drawer not found. Install it: pipx install keymap-drawer" >&2
        exit 1
    fi

# ── Clean ──────────────────────────────────────────────────────────────────

# Remove build cache and firmware artifacts.
clean:
    rm -rf {{ build_dir }} {{ out }}

# Remove everything: build cache, west workspace, ZMK source.
# You'll need to run `just init` again after this.
pristine: clean
    rm -rf .west zmk modules zephyr

# ── Docker management ─────────────────────────────────────────────────────

# Pull the ZMK build docker image.
docker-pull:
    docker pull {{ docker_image }}

# Check docker image and tool versions.
doctor:
    #!/usr/bin/env bash
    echo "━━━ Environment ━━━"
    echo "  just:       $(just --version 2>/dev/null || echo 'not found')"
    echo "  docker:     $(docker --version 2>/dev/null | head -1 || echo 'not found')"
    echo "  yq:         $(yq --version 2>/dev/null || echo 'not found')"
    echo ""

    echo "━━━ Docker image ━━━"
    echo "  image:      {{ docker_image }}"
    if docker image inspect {{ docker_image }} &>/dev/null; then
        echo "  status:     pulled ✓"
        just _run west --version 2>/dev/null && echo "" || echo "  west:       error running in container"
    else
        echo "  status:     not pulled (run 'just docker-pull')"
    fi
    echo ""

    echo "━━━ Workspace ━━━"
    if [[ -d .west ]]; then
        echo "  .west:      initialized ✓"
    else
        echo "  .west:      not initialized (run 'just init')"
    fi
    if [[ -d zmk ]]; then
        echo "  zmk:        present ✓"
        zmk_rev=$(git -C zmk rev-parse --short HEAD 2>/dev/null || echo "unknown")
        echo "  zmk rev:    $zmk_rev"
    else
        echo "  zmk:        not fetched (run 'just init')"
    fi
    echo ""

    echo "━━━ Build targets ━━━"
    just list 2>/dev/null || echo "  (install python-yq to list targets)"
