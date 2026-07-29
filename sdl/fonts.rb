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
  end
end
