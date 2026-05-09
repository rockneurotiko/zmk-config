# Rockorne — ZMK Config

Personal [ZMK firmware](https://github.com/zmkfirmware/zmk/) configuration for
the **Corne Choc Pro** (5-column, Bluetooth, with right-side encoders and
nice!view displays). Ported from a ZSA Moonlander layout.

Built against ZMK `v0.3` using
[urob's zmk-helpers](https://github.com/urob/zmk-helpers) for cleaner
Devicetree syntax. Architecture follows
[urob/zmk-config](https://github.com/urob/zmk-config): a board-agnostic
`base.keymap` with thin per-board wrappers.

## Keymap

<img src="./draw/base.svg" alt="Keymap layout" width="100%" />

(Generated with
[keymap-drawer](https://github.com/caksoylar/keymap-drawer) - run `just draw`
to regenerate.)

## Highlights

- **Dvorak US** base layout on a 5-column (36-key) split
- [**"Timeless" homerow mods**](#timeless-homerow-mods) - urob-style balanced
  HRMs with positional hold-tap, virtually no misfires
- **10 layers** with dedicated symbol, function, number, navigation, mouse, and
  Emacs layers
- **Layer lock** via `&tog` - hold a thumb to activate a layer, press the
  inner-index to lock it
- **Tap-dances** on the Emacs layer - double-tap for alternate Emacs commands
- **Emacs integration** - two layers of C-x macros, isearch, word navigation
- **Combos** - P+Y → Esc, Y+F → Caps Word
- **Mouse emulation** - cursor movement, scroll wheel, and mouse buttons
- **Conditional layer** - FN + NUM simultaneously activates the System layer
- **Encoders** - right-half only, volume/brightness rotation, mute/play-pause
  press
- **Deep sleep** - 30 min timeout for battery preservation
- **Docker-based local builds** - no Zephyr SDK install needed

## Layers

| # | Name | Activator | Description |
|---|------|-----------|-------------|
| 0 | **Base** | - | Dvorak US with homerow mods |
| 1 | **SymL** | hold Ent | Symbols left: `+ = ( ) "`, `< \| - > \`, `@ # $ %` |
| 2 | **SymR** | hold Del | Symbols right: `^ & * ? '`, `: ] [ } {`, `` ` _ / ~ ; `` |
| 3 | **Fn** | hold Bspc | Function keys F1–F12, PrtSc |
| 4 | **Num** | hold Space | Numpad (right), brightness/volume (left) |
| 5 | **Nav** | hold Esc | Arrow keys, PgUp/Dn, Home/End |
| 6 | **Mouse** | hold Tab | Mouse movement, scroll, click buttons |
| 7 | **EmacsN** | hold I | Emacs navigation: `M-b/f`, `C-a/e/r/s`, arrows |
| 8 | **EmacsW** | hold D | Emacs windows/buffers: `C-x` sequences |
| 9 | **Sys** | FN + NUM | Bluetooth select/clear, bootloader, reset |

### Thumb cluster

```
             ╭─────────┬─────────┬─────────╮ ╭─────────┬─────────┬─────────╮
Left hand:   │ Del/SymR│ Spc/Num │ Esc/Nav │ │ Tab/Mse │Bspc/Fn  │ Ent/SymL│  :Right hand
             ╰─────────┴─────────┴─────────╯ ╰─────────┴─────────┴─────────╯
```

### Homerow mods (GACS)

Control as the main finger because of the heavy-emacs usage.
Gui as the second main finger because of the heavy-tiling window managers usage (Niri, Hyprland, ...)

```
             ╭───────┬───────┬───────┬───────┬───────╮ ╭───────┬───────┬───────┬───────┬───────╮
             │       │       │       │       │       │ │       │       │       │       │       │
             │  A    │  O    │  E    │  U    │  I    │ │  D    │  H    │  T    │  N    │  S    │
             │ Shift │  Alt  │  Gui  │ Ctrl  │EmacsN │ │EmacsW │ Ctrl  │  Gui  │  Alt  │ Shift │
             ╰───────┴───────┴───────┴───────┴───────╯ ╰───────┴───────┴───────┴───────┴───────╯
```

## Timeless homerow mods

This configuration uses urob's
["timeless" HRM](https://github.com/urob/zmk-config#timeless-homerow-mods)
approach - `balanced` flavor hold-taps with positional constraints that make the
behavior virtually timer-independent:

- **`balanced` flavor** - hold triggers when another key is pressed _and_
  released (no need to wait for the tapping term during normal use)
- **`require-prior-idle-ms = 150`** - if you tapped any key less than 150ms
  ago, the HRM immediately resolves as a tap (eliminates delay during fast
  typing)
- **Positional hold-tap** - only keys on the _opposite_ hand (+ thumbs) can
  trigger a hold. Same-hand keys always produce a tap.
- **`hold-trigger-on-release`** - the positional check happens on the next
  key's _release_, allowing you to combine multiple mods on the same hand.
- **`tapping-term-ms = 280`** - large enough to not need precise timing, small
  enough for deliberate same-hand mod+alpha.
- **`quick-tap-ms = 175`** - double-tapping an HRM key quickly always produces
  the tap character.

### HRM tuning guide

| Symptom | Fix |
|---------|-----|
| Noticeable delay when tapping HRMs | Increase `require-prior-idle-ms` |
| False negatives (same-hand) | Decrease `tapping-term-ms` |
| False negatives (cross-hand) | Decrease `require-prior-idle-ms` |
| False positives (same-hand) | Increase `tapping-term-ms` |
| False positives (cross-hand) | Increase `require-prior-idle-ms` |

## Emacs layers

### EmacsN (hold I) - Navigation

| Key | Binding | Notes |
|-----|---------|-------|
| F (RT0) | `M-b` | Backward word |
| G (RT1) | PgUp / `M-S-<` | Tap-dance: 1 tap = PgUp, 2 taps = beginning of buffer |
| C (RT2) | `↑` | |
| R (RT3) | `C-a` | Beginning of line |
| L (RT4) | `M-S-%` | Query replace |
| D (RM0) | `C-r` | Isearch backward |
| H (RM1) | `←` | |
| T (RM2) | `↓` | |
| N (RM3) | `→` | |
| S (RM4) | `C-s` | Isearch forward |
| B (RB0) | `M-f` | Forward word |
| M (RB1) | PgDn / `M-S->` | Tap-dance: 1 tap = PgDn, 2 taps = end of buffer |
| W (RB2) | `C-s` / QRR | Tap-dance: 1 tap = `C-s`, 2 taps = `M-C-S-%` (query-replace-regexp) |
| V (RB3) | `C-e` | End of line |
| Z (RB4) | `C-S--` | Undo |

### EmacsW (hold D) - Windows & Buffers

All bindings are `C-x` prefix macros:

| Key | Binding | Emacs command |
|-----|---------|---------------|
| ' | `C-x 0` | Delete window |
| , | `C-x 3` | Split right |
| . | `C-x 2` | Split below |
| P | `C-x 1` | Delete other windows |
| Y | `C-Bspc` | Backward kill word |
| O | `C-x o` | Other window |
| E | `C-x b` | Switch buffer |
| U | `C-x C-s` | Save buffer |
| I | `C-k` | Kill line |
| ; | `C-x C-w` | Write file |
| Q | `C-x k` | Kill buffer |
| K | `C-x C-f` | Find file |
| X | `C-Del` | Forward kill word |

## File structure

```
zmk-config/
├── config/
│   ├── base.keymap              # Board-agnostic keymap (all layers & behaviors)
│   ├── mouse.dtsi               # Mouse emulation settings
│   ├── corne_choc_pro.keymap    # Thin board wrapper (encoder positions, sensor-bindings)
│   ├── corne_choc_pro.conf      # Board config (BT, deep sleep, pointing)
│   └── west.yml                 # West manifest (ZMK + module versions)
├── boards/arm/corne_choc_pro/   # Custom board definitions (from keebart)
├── draw/
│   ├── config.yaml              # keymap-drawer styling & binding labels
│   ├── base.yaml                # Parsed keymap (generated)
│   └── base.svg                 # Rendered keymap image (generated)
├── build.yaml                   # Build matrix (GitHub Actions + local)
├── Justfile                     # Local build commands
└── README.md
```

## Local build environment

Local builds use **Docker** - no Zephyr SDK or toolchain installation needed.

### Prerequisites

- [just](https://github.com/casey/just) - command runner
- [Docker](https://www.docker.com/) - for building firmware
- [python-yq](https://github.com/kislyuk/yq) - for parsing `build.yaml`
  (`pipx install yq`)
- [keymap-drawer](https://github.com/caksoylar/keymap-drawer) - for drawing
  the keymap (`pipx install keymap-drawer`)

### Setup

```bash
git clone https://github.com/rockneurotiko/zmk-config
cd zmk-config
just docker-pull   # Pull the ZMK build image (~2 GB, once)
just init          # Initialize west workspace + fetch ZMK & modules (~5 min)
```

### Usage

```bash
just                # List all available commands
just doctor         # Check environment & prerequisites

just build all      # Build firmware for all targets → firmware/*.uf2
just build left     # Build only left half
just build right    # Build only right half
just list           # List build targets from build.yaml
just flash left     # Copy UF2 to auto-detected mounted drive

just draw           # Parse & render keymap → draw/base.svg

just clean          # Remove build cache & firmware
just pristine       # Remove everything (need `just init` again)
just update         # Re-fetch modules after changing west.yml
```

For **native builds** (if you have `west` + Zephyr SDK installed):

```bash
DOCKER=0 just build all
```

### Workspace after `just init`

```
zmk-config/
├── config/          # Your keymap & config (this repo)
├── zmk/             # ZMK firmware source (fetched by west)
├── modules/         # ZMK modules: zmk-helpers, etc. (fetched by west)
├── .west/           # West workspace metadata
├── firmware/        # Build output: *.uf2 files (after `just build`)
└── .build/          # Build cache (intermediate files)
```

## Optional modules

The following urob modules are documented in `config/west.yml` but commented
out. Uncomment and `just update` to enable:

| Module | Description |
|--------|-------------|
| `zmk-adaptive-key` | Magic-shift / repeat key |
| `zmk-auto-layer` | Numword - auto-deactivating number layer |
| `zmk-tri-state` | Smart-mouse, alt-tab swapper |
| `zmk-leader-key` | Leader key sequences for Unicode & system commands |
| `zmk-unicode` | Unicode input (Umlauts, Greek letters, etc.) |

## Credits

- [urob/zmk-config](https://github.com/urob/zmk-config) - architecture,
  timeless HRM design, zmk-helpers macros
- [keebart/zmk-config](https://github.com/keebart/zmk-config) - Corne Choc Pro
  board definitions
- [caksoylar/keymap-drawer](https://github.com/caksoylar/keymap-drawer) -
  keymap visualization
- [ZSA Moonlander](https://www.zsa.io/moonlander) - original layout (Oryx
  config "valhalla-36-homerowmods-emacs-an")
