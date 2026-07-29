#!/bin/sh
# Builds static SDL3_ttf (with vendored FreeType/HarfBuzz) from source into
# ./install, against the SDL3 install tree handed in as $1 (the sdl3-install
# tar produced by ../sdl3/build.sh, extracted here so SDL3_ttf's CMake can
# find_package(SDL3) against a real installed package). Packages libSDL3_ttf.a
# plus the two vendored static libs (CMake's install step doesn't install
# those — they're pulled straight out of the build tree) as individual
# artifacts, and just the headers as a tar for the shim build to extract.
set -e

SDL3_TAR="$1"
SDL_TTF_REF="a42434b8c96daaf7650dbd0befe480c090d1c2eb"  # main, 2026-06-23 (no 3.3.x tag yet)

mkdir sdl3-tree
tar -xf "$SDL3_TAR" -C sdl3-tree

mkdir src && cd src
git init -q
git remote add origin https://github.com/libsdl-org/SDL_ttf.git
git fetch --depth 1 origin "$SDL_TTF_REF"
git checkout -q FETCH_HEAD
git submodule update --init --recursive --depth 1
cd ..

cmake -S src -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$(pwd)/sdl3-tree" \
  -DBUILD_SHARED_LIBS=OFF \
  -DSDLTTF_VENDORED=ON \
  -DSDLTTF_HARFBUZZ=ON \
  -DSDLTTF_PLUTOSVG=OFF \
  -DSDLTTF_INSTALL=ON \
  -DSDLTTF_SAMPLES=OFF \
  -DCMAKE_INSTALL_PREFIX="$(pwd)/install"

cmake --build build -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
cmake --install build

cp install/lib/libSDL3_ttf.a .
cp build/external/freetype-build/libfreetype.a .
cp build/external/harfbuzz-build/libharfbuzz.a .
tar -cf sdl3ttf-headers.tar -C install/include .
