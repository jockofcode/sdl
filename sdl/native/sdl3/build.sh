#!/bin/sh
# Builds static SDL3 from source into ./install, then packages it for the
# other [[build]] entries in ../../../spin.toml: libSDL3.a as an individual
# artifact (linked directly into the final binary), and the full install
# tree (headers + lib + CMake package config) tarred into one file so the
# SDL3_ttf entry can `find_package(SDL3)` against it.
set -e

SDL_REF="release-3.4.12"

git clone --depth 1 --branch "$SDL_REF" https://github.com/libsdl-org/SDL.git src

cmake -S src -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DSDL_STATIC=ON \
  -DSDL_SHARED=OFF \
  -DSDL_TEST_LIBRARY=OFF \
  -DCMAKE_INSTALL_PREFIX="$(pwd)/install"

cmake --build build -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)"
cmake --install build

cp install/lib/libSDL3.a .
tar -cf sdl3-install.tar -C install .
