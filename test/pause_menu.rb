require "sdl"

# Drives SDL::PauseMenu with synthetic key, gamepad and mouse events
# (sdl_test_push_*_event shims) and checks selection, wrap-around, the
# chosen action, and mouse hit-testing against the drawn layout.

# Drains the queue and returns the menu's decision. Real mouse motion over
# the test window would otherwise interleave with the synthetic events, so
# mouse events are only passed through when a step expects them.
def step(m, mouse = false)
  result = :none
  while (event_type = SDL::Event.poll)
    is_mouse = event_type == LibSDL::MOUSEMOTION || event_type == LibSDL::MOUSEBUTTONDOWN || event_type == LibSDL::MOUSEBUTTONUP
    next if is_mouse && !mouse
    r = m.handle(event_type)
    result = r if r != :none
  end
  result
end

S_KEY = "s".ord
W_KEY = "w".ord

SDL::Screen.open("Pause Menu Test", width: 640, height: 480) do |window, renderer|
  window.title = "Pause Menu Test"
  while SDL::Event.poll
  end
  m = SDL::PauseMenu.new
  puts m.open? == false
  m.open
  puts m.open?
  puts m.selected

  # Keyboard: down, wrap, up, choose.
  LibSDL.sdl_test_push_key_event(LibSDL::K_DOWN, 1)
  puts step(m)
  puts m.selected
  LibSDL.sdl_test_push_key_event(LibSDL::K_DOWN, 1)
  puts step(m)
  puts m.selected
  LibSDL.sdl_test_push_key_event(LibSDL::K_UP, 1)
  puts step(m)
  puts m.selected
  LibSDL.sdl_test_push_key_event(LibSDL::K_RETURN, 1)
  puts step(m)
  puts m.open? == false

  # Esc backs out.
  m.open
  LibSDL.sdl_test_push_key_event(LibSDL::K_ESCAPE, 1)
  puts step(m)
  puts m.open? == false

  # WASD and Space.
  m.open
  LibSDL.sdl_test_push_key_event(S_KEY, 1)
  puts step(m)
  puts m.selected
  LibSDL.sdl_test_push_key_event(W_KEY, 1)
  puts step(m)
  puts m.selected
  LibSDL.sdl_test_push_key_event(LibSDL::K_SPACE, 1)
  puts step(m)

  # Gamepad d-pad and A.
  m.open
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_DPAD_DOWN, 1)
  puts step(m)
  puts m.selected
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_SOUTH, 1)
  puts step(m)

  # Stick: one move per deflection, re-armed when it centres; B backs out.
  m.open
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTY, 30000)
  puts step(m)
  puts m.selected
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTY, 31000)
  puts step(m)
  puts m.selected
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTY, 0)
  puts step(m)
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTY, 30000)
  puts step(m)
  puts m.selected
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_EAST, 1)
  puts step(m)
  puts m.open? == false

  # Start resumes too.
  m.open
  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_START, 1)
  puts step(m)

  # Closed menus ignore input.
  LibSDL.sdl_test_push_key_event(LibSDL::K_DOWN, 1)
  puts step(m)
  puts m.selected

  # Mouse: hover selects, click chooses, using the drawn layout.
  m.open
  renderer.draw_color(0, 0, 0)
  renderer.clear
  m.draw(renderer, 640, 480)
  renderer.present
  r = m.item_rect(1)
  puts r[2] > 0 && r[3] > 0
  cx = (r[0] + r[2] / 2).to_f
  cy = (r[1] + r[3] / 2).to_f
  LibSDL.sdl_test_push_mouse_event(0, cx, cy)
  puts step(m, true)
  puts m.selected
  LibSDL.sdl_test_push_mouse_event(0, 5.0, 5.0)
  puts step(m, true)
  puts m.selected
  LibSDL.sdl_test_push_mouse_event(1, cx, cy)
  puts step(m, true)
  puts m.open? == false
  # Overridden coordinates win over the event's own.
  m.open
  LibSDL.sdl_test_push_mouse_event(1, 5.0, 5.0)
  event_type = SDL::Event.poll
  puts m.handle(event_type, cx.to_i, cy.to_i)

  # Custom items.
  m2 = SDL::PauseMenu.new(labels: ["RESUME", "RESTART", "QUIT"], actions: [:resume, :restart, :quit], title: "HOLD ON")
  m2.open
  LibSDL.sdl_test_push_key_event(LibSDL::K_DOWN, 1)
  puts step(m2)
  LibSDL.sdl_test_push_key_event(LibSDL::K_RETURN, 1)
  puts step(m2)
  puts m2.title
  m.draw(renderer, 640, 480)
  m.close_fonts
  m2.close_fonts
  puts "done"
end
