module SDL
  class Window
    attr_reader :ptr

    def initialize(title, x: LibSDL::WINDOWPOS_CENTERED, y: LibSDL::WINDOWPOS_CENTERED,
                   width: 800, height: 600, flags: LibSDL::WINDOW_RESIZABLE)
      @ptr = LibSDL.SDL_CreateWindow(title, width, height, flags)
      Log.write("SDL_CreateWindow: #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
      # SDL3 dropped x/y from window creation — position it separately.
      LibSDL.SDL_SetWindowPosition(@ptr, x, y) unless @ptr == nil
    end

    def width
      LibSDL.sdl_get_window_width(@ptr)
    end

    def height
      LibSDL.sdl_get_window_height(@ptr)
    end

    def title=(str)
      LibSDL.SDL_SetWindowTitle(@ptr, str)
    end

    def close
      LibSDL.SDL_DestroyWindow(@ptr)
      Log.write("SDL_DestroyWindow: done")
    end
  end
end
