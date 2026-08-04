require "sdl"

# Exercises the immediate-mode-UI-oriented additions: clip rect, filled
# polygon geometry, text measurement, clipboard, and text-input mode.
# Pixel-exact font metrics aren't asserted (those can shift with the
# vendored FreeType version) — only the relative/sanity properties an
# immediate-mode layout engine actually depends on.
puts LibSDL::TEXT_EDITING
puts LibSDL::TEXT_INPUT

SDL::Screen.open("UI Extensions", width: 320, height: 240) do |window, renderer|
  renderer.draw_color(0, 0, 0)
  renderer.clear

  puts renderer.set_clip_rect(10, 10, 100, 100)
  puts renderer.clear_clip_rect

  # Triangle
  puts renderer.fill_polygon([10.0, 10.0, 100.0, 10.0, 55.0, 90.0], 255, 0, 0)
  # Square (as a 4-point convex polygon)
  puts renderer.fill_polygon([10.0, 10.0, 60.0, 10.0, 60.0, 60.0, 10.0, 60.0], 0, 255, 0)
  # Degenerate (only 2 points) — shim guards npoints < 3, must not crash
  puts renderer.fill_polygon([10.0, 10.0, 20.0, 20.0], 0, 0, 255)

  font = SDL::Font.bundled("public_sans", 24)
  w_short, h_short = font.measure("Hi")
  w_long, h_long = font.measure("Hello, immediate mode!")
  puts w_short > 0
  puts h_short > 0
  puts w_long > w_short
  puts h_long == h_short
  font.close

  puts SDL::Clipboard.set("sdl_ui round-trip")
  puts SDL::Clipboard.get

  puts window.start_text_input
  puts window.stop_text_input
end
