require "sdl"

SDL::Log.open("/tmp/sdl_mouse_demo.log")

CIRCLE_RADIUS = 20

# sdl/fonts.rb can't build this path itself — see the comment there.
FONT_PATH = File.join(__dir__, "..", "sdl", "fonts", SDL::Fonts::VT323)

BUTTON_COLORS = {
  LibSDL::BUTTON_LEFT   => SDL::Color::RED,
  LibSDL::BUTTON_MIDDLE => SDL::Color::YELLOW,
  LibSDL::BUTTON_RIGHT  => SDL::Color::BLUE,
}

BUTTON_NAMES = {
  LibSDL::BUTTON_LEFT   => "LEFT",
  LibSDL::BUTTON_MIDDLE => "MIDDLE",
  LibSDL::BUTTON_RIGHT  => "RIGHT",
}

# Midpoint circle algorithm, filled via horizontal scanline spans — SDL3 has
# no native circle primitive, only points/lines/rects (see sdl/renderer.rb).
def fill_circle(renderer, cx, cy, radius)
  x = radius
  y = 0
  err = 0

  while x >= y
    renderer.draw_line(cx - x, cy + y, cx + x, cy + y)
    renderer.draw_line(cx - x, cy - y, cx + x, cy - y)
    renderer.draw_line(cx - y, cy + x, cx + y, cy + x)
    renderer.draw_line(cx - y, cy - x, cx + y, cy - x)

    y += 1
    err += 2 * y + 1 if err <= 0
    if err > 0
      x -= 1
      err -= 2 * x + 1
    end
  end
end

SDL::Screen.open("Mouse Demo", width: 800, height: 600) do |window, renderer|
  font = SDL::Font.new(FONT_PATH, 24)

  mx = window.width / 2
  my = window.height / 2
  held = {} # LibSDL::BUTTON_* => true while held down

  running = true
  while running
    while (event_type = SDL::Event.poll)
      if event_type == LibSDL::QUIT
        running = false
      elsif event_type == LibSDL::KEYDOWN
        running = false if SDL::Event.key_sym == LibSDL::K_ESCAPE
      elsif event_type == LibSDL::MOUSEMOTION
        mx = SDL::Event.mouse_x
        my = SDL::Event.mouse_y
      elsif event_type == LibSDL::MOUSEBUTTONDOWN
        mx = SDL::Event.mouse_x
        my = SDL::Event.mouse_y
        held[SDL::Event.mouse_button] = true
      elsif event_type == LibSDL::MOUSEBUTTONUP
        mx = SDL::Event.mouse_x
        my = SDL::Event.mouse_y
        held.delete(SDL::Event.mouse_button)
      end
    end

    renderer.draw_color(0, 0, 0, 255)
    renderer.clear

    # Circle color reflects whichever button was pressed most recently among
    # the ones still held; falls back to gray when nothing is held.
    active_button = held.keys.last
    color = active_button ? BUTTON_COLORS[active_button] : SDL::Color::GRAY
    renderer.draw_color(color[0], color[1], color[2], color[3])
    fill_circle(renderer, mx, my, CIRCLE_RADIUS)

    hud = SDL::Color::WHITE
    renderer.draw_text(font, "X: #{mx}  Y: #{my}", 8, 4, hud[0], hud[1], hud[2], hud[3])

    [LibSDL::BUTTON_LEFT, LibSDL::BUTTON_MIDDLE, LibSDL::BUTTON_RIGHT].each_with_index do |button, i|
      pressed = held[button]
      c = pressed ? BUTTON_COLORS[button] : SDL::Color::GRAY
      renderer.draw_text(font, BUTTON_NAMES[button], 8 + i * 110, 34, c[0], c[1], c[2], c[3])
    end

    renderer.present
    SDL::Screen.delay(16)
  end

  font.close
end
