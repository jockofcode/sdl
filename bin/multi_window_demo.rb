require "sdl"

SDL::Log.open("/tmp/sdl_multi_window_demo.log")

# SDL::Screen.open only ever opens one Window/Renderer pair; a second
# independent pair is just a second Window.new/Renderer.new (see the
# roadmap doc's multi-window plan — nothing about SDL::Window/SDL::Renderer
# was ever a singleton, only Screen.open's convenience wrapper is
# single-pair). SDL::Event.window_id (SDL_WindowID) plus SDL::Window#id are
# what route a polled event to the right pair below.
#
# Each window's (renderer, color, label) stays in its own separate local
# rather than one Hash whose values mix Renderer/IntArray/String per entry
# — a heterogeneous-valued Hash goes poly per key, and this binding's other
# demos hit real Spinel type-inference trouble mixing a poly value back
# into a concretely-typed call site (see gamepad_demo.rb's FACE_BUTTON_*
# comment) — so two explicit, concretely-typed panes it is.
def draw_pane(renderer, font, color, label, wid, mx, my)
  renderer.draw_color(color[0] / 4, color[1] / 4, color[2] / 4)
  renderer.clear

  renderer.draw_color(color[0], color[1], color[2])
  renderer.fill_rect(mx - 15, my - 15, 30, 30)

  hud = SDL::Color::WHITE
  renderer.draw_text(font, "Window #{label} (id=#{wid})", 8, 4, hud[0], hud[1], hud[2], hud[3])
  renderer.present
end

SDL::Screen.open("Window A (red)", width: 480, height: 320) do |window_a, renderer_a|
  window_b = SDL::Window.new("Window B (blue)", width: 480, height: 320)
  renderer_b = SDL::Renderer.new(window_b)
  font = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 24)

  id_a = window_a.id
  id_b = window_b.id

  mx_a, my_a = window_a.width / 2, window_a.height / 2
  mx_b, my_b = window_b.width / 2, window_b.height / 2

  running = true
  while running
    while (event_type = SDL::Event.poll)
      wid = SDL::Event.window_id

      if event_type == LibSDL::QUIT
        running = false
      elsif event_type == LibSDL::KEYDOWN
        running = false if SDL::Event.key_sym == LibSDL::K_ESCAPE
      elsif event_type == LibSDL::MOUSEMOTION && wid == id_a
        mx_a = SDL::Event.mouse_x
        my_a = SDL::Event.mouse_y
      elsif event_type == LibSDL::MOUSEMOTION && wid == id_b
        mx_b = SDL::Event.mouse_x
        my_b = SDL::Event.mouse_y
      end
    end

    draw_pane(renderer_a, font, SDL::Color::RED, "A", id_a, mx_a, my_a)
    draw_pane(renderer_b, font, SDL::Color::BLUE, "B", id_b, mx_b, my_b)

    SDL::Screen.delay(16)
  end

  font.close
  renderer_b.close
  window_b.close
end
