require "sdl"

# Exercises the gamepad button/axis event-field accessors deterministically,
# without needing real gamepad hardware attached, via the test-support
# sdl_test_push_gamepad_*_event shims (SDL_PushEvent-backed — see shim.c).
SDL::Screen.open("Gamepad Events Test", width: 320, height: 240) do |window, renderer|
  window.title = "Gamepad Events Test"
  renderer.draw_color(0, 0, 0)
  renderer.clear
  puts SDL::Gamepad.count >= 0

  # Drain any window-lifecycle events already queued from SDL_CreateWindow
  # first, so the polls below are guaranteed to return our own events.
  while SDL::Event.poll
  end

  LibSDL.sdl_test_push_gamepad_button_event(LibSDL::GAMEPAD_BUTTON_SOUTH, 1)
  LibSDL.sdl_test_push_gamepad_axis_event(LibSDL::GAMEPAD_AXIS_LEFTX, 12345)

  event_type = SDL::Event.poll
  puts event_type == LibSDL::EVENT_GAMEPAD_BUTTON_DOWN
  puts SDL::Event.gamepad_button == LibSDL::GAMEPAD_BUTTON_SOUTH
  puts SDL::Event.gamepad_button_down?

  event_type = SDL::Event.poll
  puts event_type == LibSDL::EVENT_GAMEPAD_AXIS_MOTION
  puts SDL::Event.gamepad_axis == LibSDL::GAMEPAD_AXIS_LEFTX
  puts SDL::Event.gamepad_axis_value
end
