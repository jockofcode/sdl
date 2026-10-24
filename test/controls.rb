require "sdl"

# Exercises SDL::Controls deterministically: synthetic key and gamepad
# events go in through the sdl_test_push_*_event shims (SDL_PushEvent-
# backed) and the merged action state comes out. gamepad: false so a real
# pad plugged into the test machine is not opened — the instance then
# accepts events from any pad id, including the shims' id 1.

def pump(c)
  while (event_type = SDL::Event.poll)
    c.handle(event_type)
  end
end

A_KEY = "a".ord
M_KEY = "m".ord

SDL::Screen.open("Controls Test", width: 320, height: 240) do |window, renderer|
  window.title = "Controls Test"
  while SDL::Event.poll
  end
  c = SDL::Controls.new(gamepad: false)
  puts c.gamepad? == false
  puts c.gamepad_name == ""

  # Gamepad button: pressed edge for one frame, held until released.
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_SOUTH, 1)
  pump(c)
  puts c.pressed?(:fire)
  puts c.held?(:fire)
  c.begin_frame
  puts c.pressed?(:fire) == false
  puts c.held?(:fire)
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_SOUTH, 0)
  pump(c)
  puts c.released?(:fire)
  puts c.held?(:fire) == false

  # D-pad gives a digital direction and full axis deflection.
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_DPAD_LEFT, 1)
  pump(c)
  puts c.dir_x == -1
  puts c.axis_x == -1.0
  puts c.held?(:left)
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_DPAD_LEFT, 0)
  pump(c)
  puts c.dir_x == 0

  # Stick: inside the deadzone nothing happens...
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTX, 5000)
  pump(c)
  puts c.dir_x == 0
  puts c.pressed?(:left) == false
  puts c.axis_x == 0.0
  # ...past it the direction engages with a pressed edge and a scaled axis...
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTX, -20000)
  pump(c)
  puts c.pressed?(:left)
  puts c.held?(:left)
  puts c.dir_x == -1
  puts (c.axis_x * 100.0).round
  # ...easing back inside the deadzone but outside the release zone keeps it...
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTX, -9000)
  pump(c)
  puts c.dir_x == -1
  puts c.released?(:left) == false
  # ...and centring releases it.
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTX, 0)
  pump(c)
  puts c.released?(:left)
  puts c.dir_x == 0
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTY, 30000)
  pump(c)
  puts c.dir_y == 1
  puts c.held?(:down)
  puts c.pressed?(:down)
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTY, 0)
  pump(c)
  puts c.dir_y == 0

  # Keyboard: two keys on one action, releasing one keeps it held.
  c.begin_frame
  LibSDL.sdl_test_push_key_event(LibSDL::K_LEFT, 1)
  LibSDL.sdl_test_push_key_event(A_KEY, 1)
  pump(c)
  puts c.pressed?(:left)
  puts c.dir_x == -1
  puts c.axis_x == -1.0
  LibSDL.sdl_test_push_key_event(LibSDL::K_LEFT, 0)
  pump(c)
  puts c.held?(:left)
  LibSDL.sdl_test_push_key_event(A_KEY, 0)
  pump(c)
  puts c.held?(:left) == false
  puts c.released?(:left)

  # Keyboard and stick disagreeing: keys win for the axis value.
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTX, -20000)
  LibSDL.sdl_test_push_key_event(LibSDL::K_RIGHT, 1)
  pump(c)
  puts c.axis_x == 1.0
  puts c.dir_x == 0
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTX, 0)
  LibSDL.sdl_test_push_key_event(LibSDL::K_RIGHT, 0)
  pump(c)

  # Rebinding: an extra key for fire, and dropping Esc from back.
  c.bind_key(:fire, LibSDL::K_UP)
  c.begin_frame
  LibSDL.sdl_test_push_key_event(LibSDL::K_UP, 1)
  pump(c)
  puts c.pressed?(:fire) && c.pressed?(:up)
  LibSDL.sdl_test_push_key_event(LibSDL::K_UP, 0)
  pump(c)
  c.clear_keys(:back)
  c.begin_frame
  LibSDL.sdl_test_push_key_event(LibSDL::K_ESCAPE, 1)
  event_type = SDL::Event.poll
  puts c.handle(event_type) == false
  puts c.pressed?(:back) == false
  LibSDL.sdl_test_push_key_event(LibSDL::K_ESCAPE, 0)
  pump(c)
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_BACK, 1)
  pump(c)
  puts c.pressed?(:back)
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_BACK, 0)
  pump(c)

  # An unbound key is reported as not consumed.
  c.begin_frame
  LibSDL.sdl_test_push_key_event(M_KEY, 1)
  event_type = SDL::Event.poll
  puts event_type == LibSDL::KEYDOWN
  puts c.handle(event_type) == false
  LibSDL.sdl_test_push_key_event(M_KEY, 0)
  pump(c)

  # Start / pause / alt buttons.
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_START, 1)
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_WEST, 1)
  pump(c)
  puts c.pressed?(:start)
  puts c.pressed?(:alt)
  puts c.pressed?(:pause) == false
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_START, 0)
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_WEST, 0)
  pump(c)

  # Gamepad directions auto-repeat after the initial delay.
  c.begin_frame
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_DPAD_RIGHT, 1)
  pump(c)
  puts c.pressed?(:right)
  c.begin_frame
  puts c.pressed?(:right) == false
  SDL::Screen.delay(400)
  c.begin_frame
  puts c.pressed?(:right)
  puts c.held?(:right)
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_DPAD_RIGHT, 0)
  pump(c)
  puts c.held?(:right) == false

  # Rumble without a pad is a no-op.
  c.rumble(0.5, 50)
  c.close
  puts "done"
end
