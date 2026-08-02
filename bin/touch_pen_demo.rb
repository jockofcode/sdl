require "sdl"

SDL::Log.open("/tmp/sdl_touch_pen_demo.log")

# Draws a marker at the last touch or pen position (normalized 0..1 touch
# coordinates are scaled to the window; pen coordinates already arrive
# window-relative in pixels — see sdl/event.rb). Most dev machines have
# neither touch nor pen hardware, so this also tracks the mouse as a
# same-shaped fallback — move the mouse to see the drawing loop working,
# and touch/pen input (a trackpad that reports SDL_EVENT_FINGER_* events,
# or a graphics tablet) will draw the same way if it's present.
SDL::Screen.open("Touch/Pen Demo", width: 640, height: 480) do |window, renderer|
  font = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 24)

  mx, my = window.width / 2, window.height / 2
  touch_pos = nil
  pen_pos = nil
  pen_down = false

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
      elsif event_type == LibSDL::EVENT_FINGER_DOWN || event_type == LibSDL::EVENT_FINGER_MOTION
        touch_pos = [(SDL::Event.touch_x * window.width).to_i, (SDL::Event.touch_y * window.height).to_i]
      elsif event_type == LibSDL::EVENT_FINGER_UP
        touch_pos = nil
      elsif event_type == LibSDL::EVENT_PEN_MOTION || event_type == LibSDL::EVENT_PEN_AXIS
        pen_pos = [SDL::Event.pen_x.to_i, SDL::Event.pen_y.to_i]
      elsif event_type == LibSDL::EVENT_PEN_DOWN
        pen_down = true
        pen_pos = [SDL::Event.pen_x.to_i, SDL::Event.pen_y.to_i]
      elsif event_type == LibSDL::EVENT_PEN_UP
        pen_down = false
      end
    end

    renderer.draw_color(15, 15, 15)
    renderer.clear

    hud = SDL::Color::WHITE
    renderer.draw_text(font, "Mouse (always available, fallback shape below):", 8, 4, hud[0], hud[1], hud[2], hud[3])
    renderer.draw_color(0, 200, 255)
    renderer.fill_rect(mx - 10, my - 10, 20, 20)

    if touch_pos
      renderer.draw_color(0, 255, 0)
      renderer.fill_rect(touch_pos[0] - 12, touch_pos[1] - 12, 24, 24)
      renderer.draw_text(font, "Touch: #{touch_pos[0]},#{touch_pos[1]}", 8, 30, 0, 255, 0, 255)
    else
      renderer.draw_text(font, "Touch: (none seen yet)", 8, 30, 128, 128, 128, 255)
    end

    if pen_pos
      color = pen_down ? [255, 0, 255] : [128, 0, 128]
      renderer.draw_color(color[0], color[1], color[2])
      renderer.fill_rect(pen_pos[0] - 8, pen_pos[1] - 8, 16, 16)
      renderer.draw_text(font, "Pen: #{pen_pos[0]},#{pen_pos[1]} down=#{pen_down}", 8, 56, color[0], color[1], color[2], 255)
    else
      renderer.draw_text(font, "Pen: (none seen yet)", 8, 56, 128, 128, 128, 255)
    end

    renderer.present
    SDL::Screen.delay(16)
  end

  font.close
end
