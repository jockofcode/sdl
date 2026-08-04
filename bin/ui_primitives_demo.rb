require "sdl"

# Showcases the Phase 0 immediate-mode-UI primitives added to this binding:
# clip/scissor rect, filled convex polygons, text measurement, clipboard,
# and text-input mode. See test/ui_extensions.rb for the non-visual
# snapshot coverage of the same additions.
SDL::Log.open("/tmp/sdl_ui_primitives.log")

SDL::Screen.open("UI Primitives Demo", width: 640, height: 480) do |window, renderer|
  font = SDL::Font.bundled("public_sans", 20)
  small_font = SDL::Font.bundled("public_sans", 14)

  window.start_text_input
  typed = ""
  clipboard_msg = ""

  running = true
  while running
    while (event_type = SDL::Event.poll)
      if event_type == LibSDL::QUIT
        running = false
      elsif event_type == LibSDL::KEYDOWN
        if SDL::Event.key_sym == LibSDL::K_ESCAPE
          running = false
        elsif SDL::Event.key_sym == LibSDL::K_BACKSPACE
          typed = typed[0, typed.length - 1] if typed.length > 0
        elsif SDL::Event.ctrl? && SDL::Event.key_sym == 99 # 'c'
          SDL::Clipboard.set(typed)
          clipboard_msg = "Copied to clipboard: #{typed}"
        elsif SDL::Event.ctrl? && SDL::Event.key_sym == 118 # 'v'
          typed = typed + SDL::Clipboard.get
          clipboard_msg = "Pasted from clipboard"
        end
      elsif event_type == LibSDL::TEXT_INPUT
        typed = typed + SDL::Event.text_input
      end
    end

    renderer.draw_color(18, 18, 22, 255)
    renderer.clear

    # --- Clip rect: a rotating-looking sweep of rects, half of it clipped
    # away by a fixed window so you can see the boundary hold steady. ---
    clip_x, clip_y, clip_w, clip_h = 40, 40, 220, 120
    renderer.draw_color(90, 90, 100, 255)
    renderer.draw_rect(clip_x, clip_y, clip_w, clip_h)

    renderer.set_clip_rect(clip_x, clip_y, clip_w, clip_h)
    t = SDL::Screen.ticks
    i = 0
    while i < 8
      bx = clip_x + 10 + i * 30
      by = clip_y + 20 + ((t / 8 + i * 40) % 140)
      renderer.draw_color(80 + i * 20, 120, 200 - i * 15, 255)
      renderer.fill_rect(bx, by, 24, 24)
      i += 1
    end
    renderer.clear_clip_rect

    # --- Filled convex polygon: a hexagon built from fill_polygon. ---
    cx, cy, radius = 380.0, 100.0, 50.0
    pts = []
    i = 0
    while i < 6
      angle = i * Math::PI / 3.0
      pts.push(cx + radius * Math.cos(angle))
      pts.push(cy + radius * Math.sin(angle))
      i += 1
    end
    renderer.fill_polygon(pts, 220, 160, 60, 255)

    # --- Text measurement: draw a box exactly sized to the label via
    # font.measure, proving the reported size matches what's drawn. ---
    label = "measure me"
    label_w, label_h = font.measure(label)
    box_x, box_y = 300, 220
    renderer.draw_color(60, 60, 70, 255)
    renderer.fill_rect(box_x, box_y, label_w + 8, label_h + 8)
    renderer.draw_text(font, label, box_x + 4, box_y + 4, 255, 255, 255, 255)

    # --- Text input + clipboard: live-typed text field, ctrl-c/ctrl-v. ---
    renderer.draw_color(40, 40, 46, 255)
    renderer.fill_rect(40, 340, 560, 40)
    renderer.draw_text(font, typed.length > 0 ? typed : "type here...", 48, 350, 200, 200, 200, 255)
    renderer.draw_text(small_font, "ctrl-c copy, ctrl-v paste, backspace to edit", 40, 300, 150, 150, 150, 255)
    renderer.draw_text(small_font, clipboard_msg, 40, 390, 140, 200, 140, 255)

    renderer.present
    SDL::Screen.delay(16)
  end

  window.stop_text_input
  small_font.close
  font.close
end
