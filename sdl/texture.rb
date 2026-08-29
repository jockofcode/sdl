module SDL
  # An image loaded (via SDL_image) straight into a Renderer-bound
  # SDL_Texture*, ready to draw with Renderer#draw_texture. Supports
  # whatever SDL_image was built with (see sdl/native/sdl3_image/build.sh —
  # PNG/JPEG plus the dependency-free formats: BMP, GIF, PNM, XCF, XPM,
  # PCX, LBM, QOI, TGA, SVG).
  class Texture
    attr_reader :ptr

    def initialize(ptr)
      @ptr = ptr
    end

    def self.load(renderer, path)
      ptr = LibSDL.IMG_LoadTexture(renderer.ptr, path)
      Log.write("IMG_LoadTexture(#{path}): #{ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
      return nil if ptr == nil
      new(ptr)
    end

    def width
      LibSDL.sdl_get_texture_width(@ptr)
    end

    def height
      LibSDL.sdl_get_texture_height(@ptr)
    end

    # Multiplies this texture's pixels by (r, g, b) at draw time — lets one
    # grayscale/white sprite be recolored per draw instead of needing a
    # separate texture file per color variant. Returns whether SDL accepted
    # the call.
    def set_color_mod(r, g, b)
      LibSDL.SDL_SetTextureColorMod(@ptr, r, g, b)
    end

    # Multiplies this texture's alpha by a/255 at draw time. Returns whether
    # SDL accepted the call.
    def set_alpha_mod(a)
      LibSDL.SDL_SetTextureAlphaMod(@ptr, a)
    end

    def close
      LibSDL.SDL_DestroyTexture(@ptr)
      Log.write("SDL_DestroyTexture: done")
    end
  end
end
