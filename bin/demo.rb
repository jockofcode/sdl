require "sdl"

SDL::Log.open("/tmp/sdl.log")

RECT_W = 40
RECT_H = 40

COLORS = [
  SDL::Color::RED,
  SDL::Color::GREEN,
  SDL::Color::BLUE,
  SDL::Color::YELLOW,
  SDL::Color::CYAN,
  SDL::Color::MAGENTA,
  SDL::Color::ORANGE,
]

SDL::Screen.open("Bouncing Box Demo", width: 800, height: 600) do |window, renderer|
  w = window.width
  h = window.height

  x  = w / 2
  y  = h / 2
  dx = 4
  dy = 3
  color_idx = 0

  running = true
  while running
    while (event_type = SDL::Event.poll)
      if event_type == LibSDL::QUIT
        running = false
      elsif event_type == LibSDL::KEYDOWN
        running = false if SDL::Event.key_sym == LibSDL::K_ESCAPE
      elsif event_type == LibSDL::EVENT_WINDOW_PIXEL_SIZE_CHANGED
        w = window.width
        h = window.height
      end
    end

    # Clear to black
    renderer.draw_color(0, 0, 0, 255)
    renderer.clear

    # Draw the bouncing rectangle
    c = COLORS[color_idx]
    renderer.draw_color(c[0], c[1], c[2], c[3])
    renderer.fill_rect(x, y, RECT_W, RECT_H)

    renderer.present
    SDL::Screen.delay(16)

    # Update position
    new_x = x + dx
    new_y = y + dy
    bounced = false

    if new_x < 0
      new_x = 0
      dx = -dx
      bounced = true
    elsif new_x + RECT_W > w
      new_x = w - RECT_W
      dx = -dx
      bounced = true
    end

    if new_y < 0
      new_y = 0
      dy = -dy
      bounced = true
    elsif new_y + RECT_H > h
      new_y = h - RECT_H
      dy = -dy
      bounced = true
    end

    color_idx = (color_idx + 1) % COLORS.length if bounced

    x = new_x
    y = new_y
  end
end
