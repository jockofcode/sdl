module SDL
  # Bundled open-license fonts, shipped as files under sdl/fonts/ (see the
  # accompanying *.LICENSE/*.OFL.txt there for terms).
  #
  # These are filenames, not paths: Spinel's __dir__/__FILE__ resolve to the
  # *compiled entry script's* own file, not the file they're written in —
  # confirmed they don't survive require_relative, so this module has no way
  # to build a working path to its own directory (sdl/fonts/). Callers must
  # locate sdl/fonts/ relative to their own (correct) __dir__, e.g.:
  #   File.join(__dir__, "..", "sdl", "fonts", SDL::Fonts::VT323)
  module Fonts
    PUBLIC_SANS    = "PublicSans-Regular.ttf"
    JETBRAINS_MONO = "JetBrainsMono-Regular.ttf"
    VT323          = "VT323-Regular.ttf"

    # Short keys for SDL::Font.bundled — select the byte array compiled
    # into the binary by build_shim.sh (see shim.c's
    # sdl_open_bundled_font), independent of the filenames above (which
    # remain for the path-based SDL::Font.new + __dir__ pattern, still
    # fine when you know the binary will run from its own source tree).
    PUBLIC_SANS_NAME    = "public_sans"
    JETBRAINS_MONO_NAME = "jetbrains_mono"
    VT323_NAME          = "vt323"
  end
end
