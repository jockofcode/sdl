module SDL
  class Renderer
    attr_reader :ptr

    FLIP_MODES = {none: 0, horizontal: 1, vertical: 2, both: 3}.freeze

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

    # x/y coerced to Float explicitly: SDL_RenderPoint/SDL_RenderLine are
    # bound straight to their real SDL functions (both declared :float in
    # ffi.rb), unlike fill_rect/draw_rect below which go through an
    # :int-typed shim that casts to float in C. Callers overwhelmingly
    # compute pixel coordinates as Ints (cursor positions, .to_i'd layout
    # math, ...); handing a statically-Int value straight to a :float FFI
    # param reinterprets its int64 bit pattern as a double instead of
    # converting the numeric value — not a type error, a garbage
    # coordinate (the point/line ends up effectively invisible, nowhere
    # near where it should be).
    def draw_point(x, y)
      LibSDL.SDL_RenderPoint(@ptr, x.to_f, y.to_f)
    end

    def draw_line(x1, y1, x2, y2)
      LibSDL.SDL_RenderLine(@ptr, x1.to_f, y1.to_f, x2.to_f, y2.to_f)
    end

    def fill_rect(x, y, w, h)
      LibSDL.sdl_render_fill_rect(@ptr, x, y, w, h)
    end

    def draw_rect(x, y, w, h)
      LibSDL.sdl_render_draw_rect(@ptr, x, y, w, h)
    end

    # Restricts drawing to (x, y, w, h) until cleared — everything outside
    # is discarded before it reaches the screen. Needed for scroll-clipped
    # regions, dropdowns, and any content that must not draw past its
    # container's bounds.
    def set_clip_rect(x, y, w, h)
      LibSDL.sdl_set_render_clip_rect(@ptr, x, y, w, h)
    end

    def clear_clip_rect
      LibSDL.sdl_clear_render_clip_rect(@ptr)
    end

    # Fills an arbitrary convex polygon with one solid color. `points` is a
    # flat array of coordinates: [x0, y0, x1, y1, x2, y2, ...], at least 3
    # points (6 elements). Used for shapes fill_rect/draw_rect can't
    # express — rounded corners, circles, arrows, ...
    def fill_polygon(points, r, g, b, a = 255)
      LibSDL.sdl_fill_convex_polygon(@ptr, points, points.length, r, g, b, a)
    end

    # Fills an arbitrary convex polygon with a texture instead of a solid
    # color. `points` is the same flat [x0,y0,x1,y1,...] pixel-space array
    # fill_polygon takes; `uvs` is a parallel flat [u0,v0,u1,v1,...] array
    # in normalized 0..1 texture space, one UV pair per point. Use this for
    # shapes draw_texture's axis-aligned dst rect can't express — a rotated
    # or sheared textured quad, a texture warped onto an arbitrary fan.
    def fill_polygon_textured(points, uvs, texture)
      LibSDL.sdl_fill_convex_polygon_textured(@ptr, texture.ptr, points, uvs, points.length)
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

    # Draws a loaded SDL::Texture at (x, y). w/h default to the texture's
    # own pixel size (reuses the same generic shim call draw_text already
    # drives — sdl_render_texture never was text-specific, see shim.c).
    #
    # src:, angle:, center:, and flip: are all optional and only reach for
    # sdl_render_texture_rotated (a heavier SDL_RenderTextureRotated call)
    # when at least one is actually used — the plain sdl_render_texture
    # path above stays the fast/common case.
    #   src:    [sx, sy, sw, sh] pixel rect within the texture to sample;
    #           nil (default) draws the whole texture.
    #   angle:  degrees, clockwise; 0 (default) means no rotation.
    #   center: [cx, cy] pivot point in dst-rect-local pixel coordinates;
    #           nil (default) pivots around the dst rect's own center.
    #   flip:   :none (default), :horizontal, :vertical, or :both.
    def draw_texture(texture, x, y, w: nil, h: nil, src: nil, angle: 0, center: nil, flip: :none)
      w ||= texture.width
      h ||= texture.height

      if src.nil? && angle == 0 && center.nil? && flip == :none
        return LibSDL.sdl_render_texture(@ptr, texture.ptr, x, y, w, h)
      end

      has_src = src ? 1 : 0
      sx, sy, sw, sh = src || [0, 0, 0, 0]
      has_center = center ? 1 : 0
      cx, cy = center || [0, 0]
      flip_mode = FLIP_MODES.fetch(flip)

      LibSDL.sdl_render_texture_rotated(@ptr, texture.ptr,
        has_src, sx, sy, sw, sh,
        x, y, w, h,
        angle.to_f, has_center, cx, cy, flip_mode)
    end

    def close
      LibSDL.SDL_DestroyRenderer(@ptr)
      Log.write("SDL_DestroyRenderer: done")
    end
  end
end
