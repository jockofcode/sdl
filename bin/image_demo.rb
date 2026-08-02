require "sdl"

SDL::Log.open("/tmp/sdl_image_demo.log")

# sdl/assets/test.bmp is an 8x8 24-bit BMP (4 solid-color quadrants:
# red/green/blue/yellow) — see the roadmap doc's image-loading plan and
# the scratchpad make_bmp.py that generated it. bin/ and sdl/ are sibling
# dirs under the repo root, same __dir__ pattern mouse_demo.rb uses for its
# font path.
BMP_PATH = File.join(__dir__, "..", "sdl", "assets", "test.bmp")

SDL::Screen.open("Image Demo", width: 640, height: 480) do |window, renderer|
  window.title = "Image Demo (#{window.width}x#{window.height})"
  font = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 24)
  texture = SDL::Texture.load(renderer, BMP_PATH)

  if texture.nil?
    SDL::Log.write("Texture.load failed: #{LibSDL.SDL_GetError}")
  end

  angle = 0.0

  running = true
  while running
    while (event_type = SDL::Event.poll)
      if event_type == LibSDL::QUIT
        running = false
      elsif event_type == LibSDL::KEYDOWN
        running = false if SDL::Event.key_sym == LibSDL::K_ESCAPE
      end
    end

    renderer.draw_color(20, 20, 30)
    renderer.clear

    if texture
      # Draw it at native size, then scaled up 8x/16x/32x, then tiled in a
      # grid — exercises draw_texture's default-size and explicit w:/h:
      # paths, and repeated draws of the same loaded Texture.
      renderer.draw_texture(texture, 20, 20)
      renderer.draw_texture(texture, 60, 20, w: 64, h: 64)
      renderer.draw_texture(texture, 140, 20, w: 128, h: 128)

      cx = 400 + (Math.cos(angle) * 60).to_i
      cy = 300 + (Math.sin(angle) * 60).to_i
      renderer.draw_texture(texture, cx, cy, w: 48, h: 48)
      angle += 0.03

      (0..7).each do |gx|
        (0..3).each do |gy|
          renderer.draw_texture(texture, 300 + gx * 20, 350 + gy * 20, w: 16, h: 16)
        end
      end

      hud = SDL::Color::WHITE
      renderer.draw_text(font, "test.bmp: #{texture.width}x#{texture.height} (native / 8x / 16x / orbiting / tiled)", 8, 440, hud[0], hud[1], hud[2], hud[3])
    else
      err = SDL::Color::RED
      renderer.draw_text(font, "Failed to load test.bmp", 8, 4, err[0], err[1], err[2], err[3])
    end

    renderer.present
    SDL::Screen.delay(16)
  end

  texture&.close
  font.close
end
