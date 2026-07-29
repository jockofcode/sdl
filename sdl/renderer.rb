module SDL
  class Renderer
    attr_reader :ptr

    # SDL3 dropped SDL_CreateRenderer's flags param (software/accelerated
    # selection went away) and its 2nd arg is now a driver-name string —
    # nil auto-picks the best available driver. VSync is a separate
    # post-creation call now instead of a creation flag.
    def initialize(window, vsync: true)
      @ptr = LibSDL.SDL_CreateRenderer(window.ptr, nil)
      Log.write("SDL_CreateRenderer: #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
      LibSDL.SDL_SetRenderVSync(@ptr, 1) if vsync && @ptr != nil
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
      LibSDL.SDL_RenderPoint(@ptr, x, y)
    end

    def draw_line(x1, y1, x2, y2)
      LibSDL.SDL_RenderLine(@ptr, x1, y1, x2, y2)
    end

    def fill_rect(x, y, w, h)
      LibSDL.sdl_render_fill_rect(@ptr, x, y, w, h)
    end

    def draw_rect(x, y, w, h)
      LibSDL.sdl_render_draw_rect(@ptr, x, y, w, h)
    end

    # Renders text at (x, y) in one shot: rasterizes to a surface, uploads it
    # as a texture, draws it, and frees both. No caching — fine for scores/
    # HUD text redrawn a few times a second, but re-rasterizes on every call,
    # so avoid this in a tight per-pixel/per-frame loop.
    def draw_text(font, text, x, y, r, g, b, a = 255)
      surface = LibSDL.sdl_ttf_render_text_blended(font.ptr, text, r, g, b, a)
      return if surface == nil

      texture = LibSDL.SDL_CreateTextureFromSurface(@ptr, surface)
      LibSDL.SDL_DestroySurface(surface)
      return if texture == nil

      w = LibSDL.sdl_get_texture_width(texture)
      h = LibSDL.sdl_get_texture_height(texture)
      LibSDL.sdl_render_texture(@ptr, texture, x, y, w, h)
      LibSDL.SDL_DestroyTexture(texture)
    end

    def close
      LibSDL.SDL_DestroyRenderer(@ptr)
      Log.write("SDL_DestroyRenderer: done")
    end
  end
end
