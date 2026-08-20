#!/bin/sh
# Produces the link inputs that reach every SYSTEM library SDL3 (+
# SDL3_ttf/SDL3_image) need beyond the static .a's the other [[build]]
# entries in this package already produce: macOS's system Frameworks, or
# Linux's X11/audio/etc shared libraries.
#
# spin.toml's [native] libs is a flat, unconditional list -- the format has
# no per-platform table/conditional, and every entry runs unconditionally
# (no OS-aware feature gating exists to skip one on the "wrong" host; see
# native_build_libs_for in the spin tool). So this entry always runs, on
# whichever host is doing the build, and always produces the SAME set of
# declared artifact names -- the 20 macOS framework/lib stub names spin.toml
# used to reference directly by absolute Xcode path, plus one more,
# system_libs.ld -- regardless of which OS that host is. Each name gets
# its REAL content only when it matches the current host; every other name
# gets a harmless placeholder: a zero-member static archive, which every
# linker (ld64 or GNU ld) accepts and silently contributes nothing for.
# That lets spin.toml's [native] libs reference all 21 names unconditionally
# on macOS or Linux alike, with a manifest format that has no idea platforms
# exist.
set -e

SDL3_TAR="$1"

ar rcs empty.a   # zero-member archive: the portable "not needed on this
                 # platform" stand-in a linker just ignores.

MAC_FRAMEWORKS="CoreText CoreGraphics CoreFoundation CoreMedia CoreVideo Cocoa UniformTypeIdentifiers IOKit ForceFeedback Carbon CoreAudio AudioToolbox AVFoundation Foundation GameController Metal QuartzCore CoreHaptics"
MAC_LIBS="libobjc libpthread"

if [ "$(uname)" = "Darwin" ]; then
  XCODE_SDK="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
  for f in $MAC_FRAMEWORKS; do
    cp "$XCODE_SDK/System/Library/Frameworks/$f.framework/$f.tbd" "$f.tbd"
  done
  for l in $MAC_LIBS; do
    cp "$XCODE_SDK/usr/lib/$l.tbd" "$l.tbd"
  done
  cp empty.a system_libs.ld
else
  for f in $MAC_FRAMEWORKS $MAC_LIBS; do
    cp empty.a "$f.tbd"
  done

  # Linux: bundle every system shared library into ONE GNU-ld linker
  # script via GROUP() -- ld auto-detects a non-ELF/non-archive input as a
  # linker script with no special flag needed, the same way a bare .tbd
  # works as a direct link input on macOS. The list comes from the real
  # sdl3.pc this package's own SDL3 build (entry 1) just produced, not a
  # hand-guessed set, so it tracks whatever CMake actually configured
  # against the libraries available on the build host.
  mkdir sdl3-tree
  tar -xf "$SDL3_TAR" -C sdl3-tree
  PC="sdl3-tree/lib/pkgconfig/sdl3.pc"
  LIBS=$(grep -E '^Libs' "$PC" | sed 's/^Libs[^:]*: *//' | tr ' ' '\n' | grep '^-l' | grep -v '^-lSDL3$' | sort -u)
  {
    echo "GROUP ("
    echo "  -lpthread -ldl -lm"
    for l in $LIBS; do echo "  $l"; done
    echo ")"
  } > system_libs.ld
fi
