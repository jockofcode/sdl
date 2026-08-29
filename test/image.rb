require "sdl"

# Exercises both SDL_image paths: the one-step SDL::Texture.load (straight
# to a Renderer-bound texture) and the lower-level IMG_Load -> SDL_Surface
# -> sdl_surface_width/height path Texture.load itself doesn't need but the
# binding still exposes. sdl/assets/test.bmp is an 8x8 24-bit hand-built
# fixture (see the scratchpad make_bmp.py that generated it) — BMP decodes
# with zero external dependency, unlike the vendored PNG/JPEG paths.
SDL::Screen.open("Image Test", width: 320, height: 240) do |window, renderer|
  window.title = "Image Test"
  bmp_path = File.join(__dir__, "..", "sdl", "assets", "test.bmp")

  texture = SDL::Texture.load(renderer, bmp_path)
  puts texture != nil
  puts texture.width
  puts texture.height

  # Texture tinting (SDL_SetTextureColorMod/AlphaMod) — multiplies the
  # texture's pixels by these values at draw time; both return whether SDL
  # accepted the call.
  puts texture.set_color_mod(128, 64, 255)
  puts texture.set_alpha_mod(200)

  texture.close

  surface = LibSDL.IMG_Load(bmp_path)
  puts surface != nil
  puts LibSDL.sdl_surface_width(surface)
  puts LibSDL.sdl_surface_height(surface)
  LibSDL.SDL_DestroySurface(surface)
end
