#!/bin/sh
# Compiles shim.c against SDL3/SDL3_ttf headers extracted from the tars
# produced by native/sdl3/build.sh ($1) and native/sdl3_ttf/build.sh ($2) —
# see spin.toml's [[build]] entries.
set -e

SDL3_TAR="$1"
SDL3_TTF_HEADERS_TAR="$2"

mkdir -p _hdrs/sdl3 _hdrs/sdl3_ttf
tar -xf "$SDL3_TAR" -C _hdrs/sdl3
tar -xf "$SDL3_TTF_HEADERS_TAR" -C _hdrs/sdl3_ttf

cc -O2 -I_hdrs/sdl3/include -I_hdrs/sdl3_ttf -c shim.c -o shim.o
ar rcs libsdl_shim.a shim.o
