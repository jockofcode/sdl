require "sdl"

# Multi-window: SDL::Screen.open still only opens one Window/Renderer pair,
# but Window.new/Renderer.new (unchanged — see sdl/window.rb, sdl/renderer.rb)
# were never a singleton at the SDL level, so a second independent pair opens
# fine alongside it. SDL::Window#id (SDL_GetWindowID) is what a multi-window
# program uses to route SDL::Event.window_id back to the right pair — see
# bin/multi_window_demo.rb for that dispatch exercised against real events.
SDL::Screen.open("Window A", width: 320, height: 240) do |window_a, renderer_a|
  window_b = SDL::Window.new("Window B", width: 320, height: 240)
  renderer_b = SDL::Renderer.new(window_b)

  renderer_a.draw_color(0, 0, 0)
  renderer_a.clear

  puts window_a.id > 0
  puts window_b.id > 0
  puts(window_a.id != window_b.id)
  puts window_b.width
  puts window_b.height

  renderer_b.close
  window_b.close
end
