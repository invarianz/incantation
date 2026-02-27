<p align="center">
  <img src="data/icons/128.svg" alt="Incantation" width="128" height="128">
</p>

<h1 align="center">Incantation</h1>

<p align="center">
  <strong>Learn to code the way wizards learn to cast</strong>
</p>

<p align="center">
  <a href="https://github.com/invarianz/incantation/actions/workflows/build-test.yml"><img src="https://github.com/invarianz/incantation/actions/workflows/build-test.yml/badge.svg" alt="Build & Test"></a>
  <a href="https://github.com/invarianz/incantation/blob/main/COPYING"><img src="https://img.shields.io/badge/license-GPL--3.0--or--later-blue.svg" alt="License: GPL-3.0-or-later"></a>
  <img src="https://img.shields.io/badge/platform-elementary%20OS%208-64BAFF.svg" alt="Platform: elementary OS 8">
  <img src="https://img.shields.io/badge/GTK-4-4A86CF.svg" alt="GTK 4">
</p>

---

Master programming through daily ritual, spaced repetition, and the slow accumulation of arcane power. Every spell you learn is a real coding concept you can use.

## Building from source

```bash
# Install dependencies (elementary OS 8 / Ubuntu 24.04)
sudo apt install valac meson libgranite-7-dev libgtk-4-dev \
  libjson-glib-dev libsqlite3-dev flatpak-builder

# Build and install as Flatpak (recommended)
flatpak-builder --user --install --force-clean flatpak-build io.github.invarianz.incantation.yml

# Or build locally for development
meson setup build
meson compile -C build
meson test -C build
```

## License

GPL-3.0-or-later
