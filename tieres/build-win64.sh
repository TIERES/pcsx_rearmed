#!/bin/bash
# Builds pcsx_rearmed_libretro.dll (Windows x64) from this branch - the core
# shipped with RetroArch FFW TIERES. See README-TIERES.md.
#
# Run from an MSYS2 MINGW64 shell, at the repository root or anywhere:
#   bash tieres/build-win64.sh
set -e
cd "$(dirname "$0")/.."

# The Makefiles embed `git describe` / `git rev-parse` of TIERES_BASE into
# the core's version strings. MSYS2 ships no git - borrow Git for Windows'
# if needed. Without git the version comes out empty and RetroArch TIERES'
# [SYNC] fingerprint reports a different core.
command -v git > /dev/null 2>&1 || export PATH="$PATH:/c/Program Files/Git/cmd"
git rev-parse --verify -q 8625c39 > /dev/null || { echo "missing upstream history (clone without --depth)"; exit 1; }

make -f Makefile.libretro platform=win clean > /dev/null 2>&1 || true
make -f Makefile.libretro platform=win -j"$(nproc)"

grep -a -q "r26l-84-g8625c39" pcsx_rearmed_libretro.dll || { echo "version string missing - is git reachable?"; exit 1; }
echo "OK: $(pwd)/pcsx_rearmed_libretro.dll"
