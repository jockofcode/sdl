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

# Embed the bundled fonts (sdl/fonts/*.ttf) as compiled-in byte arrays --
# see bin2c.c and shim.c's sdl_open_bundled_font. This is what lets
# SDL::Font.bundled load them with no runtime filesystem path at all,
# unlike SDL::Font.new(path, ...), which depends on __dir__ (a
# compile-time literal of the source tree, not the running binary's
# location -- see the README's "Fonts and portability" section).
cc -O2 -o bin2c bin2c.c
./bin2c fonts/VT323-Regular.ttf sdl_font_bytes_vt323 > fonts_embed.c
./bin2c fonts/PublicSans-Regular.ttf sdl_font_bytes_public_sans >> fonts_embed.c
./bin2c fonts/JetBrainsMono-Regular.ttf sdl_font_bytes_jetbrains_mono >> fonts_embed.c

cc -O2 -I_hdrs/sdl3/include -I_hdrs/sdl3_ttf -c shim.c -o shim.o
cc -O2 -c fonts_embed.c -o fonts_embed.o
ar rcs libsdl_shim.a shim.o fonts_embed.o
