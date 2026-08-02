require "sdl"

# Exercises the touch event-field accessors deterministically via
# sdl_test_push_touch_event (SDL_PushEvent-backed — see shim.c). Values are
# exact binary fractions (0.5, 0.25, 0.75, -0.25) so their float32 -> Ruby
# Float round-trip prints cleanly with no binary-fraction noise.
SDL::Screen.open("Touch Events Test", width: 320, height: 240) do |window, renderer|
  window.title = "Touch Events Test"
  renderer.draw_color(0, 0, 0)
  renderer.clear
  while SDL::Event.poll
  end

  LibSDL.sdl_test_push_touch_event(0.5, 0.25, 0.5, -0.25, 0.75)

  event_type = SDL::Event.poll
  puts event_type == LibSDL::EVENT_FINGER_DOWN
  puts SDL::Event.touch_x
  puts SDL::Event.touch_y
  puts SDL::Event.touch_dx
  puts SDL::Event.touch_dy
  puts SDL::Event.touch_pressure
end
