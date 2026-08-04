module SDL
  class Font
    attr_reader :ptr

    # Loads a font from a filesystem path, or (from_bundle: true) one of
    # sdl's bundled fonts straight from the bytes compiled into this
    # binary by build_shim.sh -- see SDL::Font.bundled below.
    #
    # A path built from Spinel's __dir__ (as older examples did) only
    # resolves on the machine that ran `spin build` -- __dir__ is a
    # compile-time literal of the source tree, not the running
    # executable's location, so it does not survive copying a compiled
    # binary elsewhere. Prefer SDL::Font.bundled for sdl's own fonts,
    # which has no path dependency at all.
    def initialize(path_or_name, size, from_bundle: false)
      if from_bundle
        @ptr = LibSDL.sdl_open_bundled_font(path_or_name, size.to_f)
        Log.write("sdl_open_bundled_font(#{path_or_name}, #{size}): #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
      else
        @ptr = LibSDL.TTF_OpenFont(path_or_name, size.to_f)
        Log.write("TTF_OpenFont(#{path_or_name}, #{size}): #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
      end
    end

    # Loads one of sdl's bundled fonts (SDL::Fonts::VT323_NAME,
    # ::PUBLIC_SANS_NAME, ::JETBRAINS_MONO_NAME) straight from the bytes
    # compiled into this binary — no filesystem path involved, so it
    # works the same whether run from the source tree or as a
    # standalone binary copied to another machine.
    def self.bundled(name, size)
      new(name, size, from_bundle: true)
    end

    def close
      LibSDL.TTF_CloseFont(@ptr)
    end

    # [width, height] in pixels this text would occupy if rendered — no
    # wrapping applied. Needed for layout: auto-sizing buttons/labels and
    # placing a text-field caret at the right on-screen x.
    def measure(text)
      [LibSDL.sdl_measure_text_width(@ptr, text), LibSDL.sdl_measure_text_height(@ptr, text)]
    end
  end
end
