module SDL
  class Renderer
    attr_reader :ptr

    def initialize(window, flags: LibSDL::RENDERER_ACCELERATED | LibSDL::RENDERER_PRESENTVSYNC)
      @ptr = LibSDL.SDL_CreateRenderer(window.ptr, -1, flags)
      Log.write("SDL_CreateRenderer: #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
    end

    def draw_color(r, g, b, a = 255)
      LibSDL.SDL_SetRenderDrawColor(@ptr, r, g, b, a)
    end

    def clear
      LibSDL.SDL_RenderClear(@ptr)
    end

    def present
      LibSDL.SDL_RenderPresent(@ptr)
    end

    def draw_point(x, y)
      LibSDL.SDL_RenderDrawPoint(@ptr, x, y)
    end

    def draw_line(x1, y1, x2, y2)
      LibSDL.SDL_RenderDrawLine(@ptr, x1, y1, x2, y2)
    end

    def fill_rect(x, y, w, h)
      LibSDL.sdl_render_fill_rect(@ptr, x, y, w, h)
    end

    def draw_rect(x, y, w, h)
      LibSDL.sdl_render_draw_rect(@ptr, x, y, w, h)
    end

    def close
      LibSDL.SDL_DestroyRenderer(@ptr)
      Log.write("SDL_DestroyRenderer: done")
    end
  end
end
