module SDL
  class Window
    attr_reader :ptr

    def initialize(title, x: LibSDL::WINDOWPOS_CENTERED, y: LibSDL::WINDOWPOS_CENTERED,
                   width: 800, height: 600, flags: LibSDL::WINDOW_SHOWN | LibSDL::WINDOW_RESIZABLE)
      @ptr = LibSDL.SDL_CreateWindow(title, x, y, width, height, flags)
      Log.write("SDL_CreateWindow: #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
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
