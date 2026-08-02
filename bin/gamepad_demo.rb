require "sdl"

SDL::Log.open("/tmp/sdl_gamepad_demo.log")

# Separate parallel Hashes/Arrays rather than mixed-type [id, label, color]
# tuples — destructuring a poly 3-tuple (int + string + int-array in one
# array literal) trips Spinel's static type inference the moment one branch
# of a ternary needs a concretely-typed IntArray (SDL::Color::GRAY) and the
# other holds the destructured, poly-typed tuple element. Same shape
# mouse_demo.rb already uses (BUTTON_COLORS / BUTTON_NAMES) for exactly this
# reason.
FACE_BUTTON_IDS = [
  LibSDL::GAMEPAD_BUTTON_SOUTH,
  LibSDL::GAMEPAD_BUTTON_EAST,
  LibSDL::GAMEPAD_BUTTON_WEST,
  LibSDL::GAMEPAD_BUTTON_NORTH,
]

FACE_BUTTON_LABELS = {
  LibSDL::GAMEPAD_BUTTON_SOUTH => "A/South",
  LibSDL::GAMEPAD_BUTTON_EAST  => "B/East",
  LibSDL::GAMEPAD_BUTTON_WEST  => "X/West",
  LibSDL::GAMEPAD_BUTTON_NORTH => "Y/North",
}

FACE_BUTTON_COLORS = {
  LibSDL::GAMEPAD_BUTTON_SOUTH => SDL::Color::GREEN,
  LibSDL::GAMEPAD_BUTTON_EAST  => SDL::Color::RED,
  LibSDL::GAMEPAD_BUTTON_WEST  => SDL::Color::BLUE,
  LibSDL::GAMEPAD_BUTTON_NORTH => SDL::Color::YELLOW,
}

AXIS_IDS = [
  LibSDL::GAMEPAD_AXIS_LEFTX,
  LibSDL::GAMEPAD_AXIS_LEFTY,
  LibSDL::GAMEPAD_AXIS_RIGHTX,
  LibSDL::GAMEPAD_AXIS_RIGHTY,
]

AXIS_LABELS = {
  LibSDL::GAMEPAD_AXIS_LEFTX  => "Left X",
  LibSDL::GAMEPAD_AXIS_LEFTY  => "Left Y",
  LibSDL::GAMEPAD_AXIS_RIGHTX => "Right X",
  LibSDL::GAMEPAD_AXIS_RIGHTY => "Right Y",
}

SDL::Screen.open("Gamepad Demo", width: 640, height: 480) do |window, renderer|
  window.title = "Gamepad Demo (#{window.width}x#{window.height})"
  font = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 24)

  pad = SDL::Gamepad.open(0)
  SDL::Log.write("Gamepad.open(0): #{pad ? pad.name : "none connected"}")

  running = true
  while running
    while (event_type = SDL::Event.poll)
      if event_type == LibSDL::QUIT
        running = false
      elsif event_type == LibSDL::KEYDOWN
        running = false if SDL::Event.key_sym == LibSDL::K_ESCAPE
      elsif event_type == LibSDL::EVENT_GAMEPAD_ADDED && pad.nil?
        pad = SDL::Gamepad.open(0)
      elsif event_type == LibSDL::EVENT_GAMEPAD_BUTTON_DOWN
        pad&.rumble(low: 20000, high: 20000, duration_ms: 120)
      end
    end

    renderer.draw_color(0, 0, 0)
    renderer.clear

    if pad && pad.connected?
      hud = SDL::Color::WHITE
      renderer.draw_text(font, "Connected: #{pad.name}  (#{SDL::Gamepad.count} total)", 8, 4, hud[0], hud[1], hud[2], hud[3])

      FACE_BUTTON_IDS.each_with_index do |button, i|
        pressed = pad.button(button)
        c = pressed ? FACE_BUTTON_COLORS[button] : SDL::Color::GRAY
        renderer.draw_color(c[0], c[1], c[2], c[3])
        renderer.fill_rect(20 + i * 100, 60, 80, 80)
        renderer.draw_text(font, FACE_BUTTON_LABELS[button], 20 + i * 100, 145, c[0], c[1], c[2], c[3])
      end

      AXIS_IDS.each_with_index do |axis, i|
        value = pad.axis(axis)
        # -32768..32767 -> a horizontal bar centered at x=220, +/-100px
        bar_w = (value.to_f / 32767.0 * 100).to_i
        y = 220 + i * 40
        renderer.draw_color(80, 80, 80, 255)
        renderer.draw_line(120, y, 320, y)
        renderer.draw_color(0, 255, 255, 255)
        if bar_w >= 0
          renderer.fill_rect(220, y - 6, bar_w, 12)
        else
          renderer.fill_rect(220 + bar_w, y - 6, -bar_w, 12)
        end
        renderer.draw_text(font, "#{AXIS_LABELS[axis]}: #{value}", 340, y - 10, hud[0], hud[1], hud[2], hud[3])
      end
    else
      hud = SDL::Color::GRAY
      renderer.draw_text(font, "No gamepad connected — plug one in (EVENT_GAMEPAD_ADDED is handled live)", 8, 4, hud[0], hud[1], hud[2], hud[3])
    end

    renderer.present
    SDL::Screen.delay(16)
  end

  pad&.close
  font.close
end
