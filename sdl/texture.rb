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

    def close
      LibSDL.SDL_DestroyTexture(@ptr)
      Log.write("SDL_DestroyTexture: done")
    end
  end
end
