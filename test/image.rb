require "sdl"

# Exercises both SDL_image paths: the one-step SDL::Texture.load (straight
# to a Renderer-bound texture) and the lower-level IMG_Load -> SDL_Surface
# -> sdl_surface_width/height path Texture.load itself doesn't need but the
# binding still exposes. sdl/assets/test.bmp is an 8x8 24-bit hand-built
# fixture (see the scratchpad make_bmp.py that generated it) — BMP decodes
# with zero external dependency, unlike the vendored PNG/JPEG paths. Also
# covers texture tinting (SDL_SetTextureColorMod/AlphaMod), draw_texture's
# src:/angle:/center:/flip: options, and fill_polygon_textured (all in
# sdl/renderer.rb / sdl/texture.rb).
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

  # draw_texture's rotation/source-rect path (sdl_render_texture_rotated) —
  # exercised separately from the plain sdl_render_texture fast path above,
  # which stays the no-src/no-angle/no-center/no-flip default.
  puts renderer.draw_texture(texture, 0, 0, src: [0, 0, 4, 4])
  puts renderer.draw_texture(texture, 0, 0, angle: 45)
  puts renderer.draw_texture(texture, 0, 0, angle: 45, center: [4, 4], flip: :horizontal)

  # Texture-mapped convex polygon fill (sdl_fill_convex_polygon_textured) —
  # a unit-square UV mapping onto a 50x50 screen-space square.
  uvs = [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0]
  puts renderer.fill_polygon_textured([10.0, 10.0, 60.0, 10.0, 60.0, 60.0, 10.0, 60.0], uvs, texture)
  # Degenerate (only 2 points) — shim guards npoints < 3, must not crash
  puts renderer.fill_polygon_textured([10.0, 10.0, 20.0, 20.0], [0.0, 0.0, 1.0, 1.0], texture)

  texture.close

  surface = LibSDL.IMG_Load(bmp_path)
  puts surface != nil
  puts LibSDL.sdl_surface_width(surface)
  puts LibSDL.sdl_surface_height(surface)
  LibSDL.SDL_DestroySurface(surface)
end
