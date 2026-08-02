require "sdl"

# Exercises the pen event-field accessors deterministically via
# sdl_test_push_pen_event (SDL_PushEvent-backed — see shim.c), which injects
# an SDL_EVENT_PEN_AXIS / SDL_PEN_AXIS_PRESSURE event.
SDL::Screen.open("Pen Events Test", width: 320, height: 240) do |window, renderer|
  window.title = "Pen Events Test"
  renderer.draw_color(0, 0, 0)
  renderer.clear
  while SDL::Event.poll
  end

  LibSDL.sdl_test_push_pen_event(100.0, 50.0, 0.625)

  event_type = SDL::Event.poll
  puts event_type == LibSDL::EVENT_PEN_AXIS
  puts SDL::Event.pen_x
  puts SDL::Event.pen_y
  puts SDL::Event.pen_axis == LibSDL::PEN_AXIS_PRESSURE
  puts SDL::Event.pen_axis_value
end
