#!/bin/sh
# Builds static SDL3_image (with vendored libpng/zlib/libjpeg for PNG/JPEG
# support) from source into ./install, against the SDL3 install tree handed
# in as $1 (the sdl3-install tar produced by ../sdl3/build.sh). Structurally
# mirrors ../sdl3_ttf/build.sh, with one deliberate difference: instead of
# copying each vendored static lib out by its guessed filename (fragile —
# SDL_image's FetchContent'd libpng/zlib/libjpeg target names aren't
# confirmed from this environment, and a wrong guess fails the whole
# SDL3+SDL3_ttf+SDL3_image rebuild, which shim.c edits force on every
# iteration — see spin.toml), every static archive `cmake --build` produced
# gets merged into ONE bundle via `libtool -static` and shipped as a single
# artifact. Robust to whatever the vendored dep target names actually are.
#
# No --branch pin: SDL_image's tag history couldn't be verified from this
# environment (no network browsing at plan time), so this clones the default
# branch HEAD rather than risk a `git fetch` failure on a guessed ref name.
# Pin to a specific commit once a known-good ref is confirmed, same as
# sdl3_ttf/build.sh does.
#
# Only PNG and JPEG decoders are enabled (the two formats worth the vendored
# build-time cost for a first cut); AVIF/WEBP/TIFF/JXL are left off to keep
# this build from also vendoring libavif/libwebp/libtiff/libjxl. BMP, GIF,
# PNM, XCF, XPM, PCX, LBM, QOI, TGA, SVG need no external library and stay at
# their CMake defaults (all ON).
set -e

SDL3_TAR="$1"

mkdir sdl3-tree
tar -xf "$SDL3_TAR" -C sdl3-tree

mkdir src && cd src
git init -q
git remote add origin https://github.com/libsdl-org/SDL_image.git
git fetch --depth 1 origin main
git checkout -q FETCH_HEAD
# Only the submodules PNG/JPEG actually need -- `--recursive` here would
# also pull aom/dav1d/libavif/libwebp/libtiff/libjxl (and libjxl's own
# large nested submodule tree: testdata/brotli/googletest/highway/lcms/
# skcms/zlib) despite those codecs being off below, adding many minutes
# to every rebuild for nothing this build ever links.
git submodule update --init --depth 1 external/libpng external/jpeg external/zlib
cd ..

cmake -S src -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$(pwd)/sdl3-tree" \
  -DBUILD_SHARED_LIBS=OFF \
  -DSDLIMAGE_VENDORED=ON \
  -DSDLIMAGE_PNG=ON \
  -DSDLIMAGE_JPG=ON \
  -DSDLIMAGE_AVIF=OFF \
  -DSDLIMAGE_WEBP=OFF \
  -DSDLIMAGE_TIF=OFF \
  -DSDLIMAGE_JXL=OFF \
  -DSDLIMAGE_INSTALL=ON \
  -DSDLIMAGE_SAMPLES=OFF \
  -DCMAKE_INSTALL_PREFIX="$(pwd)/install"

cmake --build build -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
cmake --install build

# Merge libSDL3_image.a plus every vendored static dep (libpng/zlib/libjpeg,
# whatever their exact target names are) into one archive, so spin.toml
# doesn't need to name each one. Done via `ar` (extract each archive's
# objects into its own scratch subdir, so same-named objects from different
# archives -- e.g. two "options.c.o" -- don't collide, then re-archive them
# all together) rather than macOS's `libtool -static`: that command is
# Apple's cctools libtool and doesn't exist on Linux (GNU libtool is a
# different tool with different flags), while `ar`/`ranlib` are the same
# command on both.
ALL_ARCHIVES=$(find "$(pwd)/build" -name '*.a' -type f)
rm -rf merge
mkdir merge
i=0
for a in $ALL_ARCHIVES; do
  d="merge/$i"
  mkdir -p "$d"
  (cd "$d" && ar x "$a")
  i=$((i + 1))
done
ar rcs libSDL3_image_bundle.a merge/*/*.o
ranlib libSDL3_image_bundle.a
tar -cf sdl3image-headers.tar -C install/include .
