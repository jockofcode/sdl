module SDL
  # A pause menu any game can drop in, so Esc pauses instead of quitting:
  #
  #   menu = SDL::PauseMenu.new                 # RESUME / QUIT by default
  #   while (event_type = SDL::Event.poll)
  #     if event_type == LibSDL::QUIT
  #       running = false
  #     elsif menu.open?
  #       running = false if menu.handle(event_type) == :quit
  #     elsif event_type == LibSDL::KEYDOWN && SDL::Event.key_sym == LibSDL::K_ESCAPE
  #       menu.open
  #     ...
  #   end
  #   game.update(dt) unless menu.open?
  #   view.draw(game)
  #   menu.draw(renderer, WINDOW_W, WINDOW_H)
  #
  # Up/Down (W/S, d-pad, left stick) move, Enter / Space / A choose,
  # Esc / B / Back / Start resume. The mouse hovers and clicks items too.
  # handle returns :none while nothing was decided, otherwise the chosen
  # action symbol (:resume closes the menu like any other choice). Drawn
  # as a dimmed overlay with a centred panel in the bundled VT323 font, in
  # whatever coordinate space the game passes as w, h.
  class PauseMenu
    W_KEY = "w".ord
    S_KEY = "s".ord
    STICK_ON  = 20000
    STICK_OFF = 10000

    attr_reader :selected, :labels, :actions, :title

    def initialize(labels: ["RESUME", "QUIT"], actions: [:resume, :quit], title: "PAUSED", size: 40)
      @labels = labels
      @actions = actions
      @title = title
      @size = size
      @open = false
      @selected = 0
      @stick_idle = true
      @font = Font.bundled(Fonts::VT323_NAME, size)
      @title_font = Font.bundled(Fonts::VT323_NAME, size * 3 / 2)
      @hint_font = Font.bundled(Fonts::VT323_NAME, size * 3 / 5)
      # Item hit boxes from the last draw, for the mouse.
      @item_x = 0
      @item_y = 0
      @item_w = 0
      @item_h = 0
    end

    def open
      @open = true
      @selected = 0
      @stick_idle = true
    end

    def close
      @open = false
    end

    def open?
      @open
    end

    def toggle
      if @open
        close
      else
        open
      end
    end

    def move(delta)
      n = @labels.length
      @selected = (@selected + delta + n) % n
    end

    def choose
      @open = false
      @actions[@selected]
    end

    def resume
      @open = false
      :resume
    end

    # Feed events here while open? is true. mouse_x / mouse_y override the
    # event's own coordinates for games that map the mouse themselves
    # (logical presentation, letterboxing).
    def handle(event_type, mouse_x = -1, mouse_y = -1)
      return :none unless @open
      if event_type == LibSDL::KEYDOWN
        key = Event.key_sym
        if key == LibSDL::K_UP || key == W_KEY
          move(-1)
        elsif key == LibSDL::K_DOWN || key == S_KEY
          move(1)
        elsif key == LibSDL::K_RETURN || key == LibSDL::K_SPACE
          return choose
        elsif key == LibSDL::K_ESCAPE
          return resume
        end
        return :none
      elsif event_type == LibSDL::EVENT_GAMEPAD_BUTTON_DOWN
        button = Event.gamepad_button
        if button == LibSDL::GAMEPAD_BUTTON_DPAD_UP
          move(-1)
        elsif button == LibSDL::GAMEPAD_BUTTON_DPAD_DOWN
          move(1)
        elsif button == LibSDL::GAMEPAD_BUTTON_SOUTH
          return choose
        elsif button == LibSDL::GAMEPAD_BUTTON_EAST || button == LibSDL::GAMEPAD_BUTTON_BACK || button == LibSDL::GAMEPAD_BUTTON_START
          return resume
        end
        return :none
      elsif event_type == LibSDL::EVENT_GAMEPAD_AXIS_MOTION
        return :none unless Event.gamepad_axis == LibSDL::GAMEPAD_AXIS_LEFTY
        v = Event.gamepad_axis_value
        if v.abs < STICK_OFF
          @stick_idle = true
        elsif @stick_idle && v.abs >= STICK_ON
          @stick_idle = false
          move(v < 0 ? -1 : 1)
        end
        return :none
      elsif event_type == LibSDL::MOUSEMOTION
        i = item_at(mouse_x < 0 ? Event.mouse_x : mouse_x, mouse_y < 0 ? Event.mouse_y : mouse_y)
        @selected = i if i >= 0
        return :none
      elsif event_type == LibSDL::MOUSEBUTTONDOWN
        i = item_at(mouse_x < 0 ? Event.mouse_x : mouse_x, mouse_y < 0 ? Event.mouse_y : mouse_y)
        if i >= 0
          @selected = i
          return choose
        end
        return :none
      end
      :none
    end

    # [x, y, w, h] of item i as last drawn (all zero before the first draw).
    def item_rect(i)
      [@item_x, @item_y + i * @item_h, @item_w, @item_h]
    end

    def item_at(mx, my)
      return -1 if @item_w == 0 || @item_h == 0
      return -1 if mx < @item_x || mx >= @item_x + @item_w || my < @item_y
      row = (my - @item_y) / @item_h
      row < @labels.length ? row : -1
    end

    # w, h: the size of the space being drawn into (the window, or the
    # game's logical size when it uses logical presentation).
    def draw(renderer, w, h)
      return unless @open
      saved = IO::Buffer.new(4)
      LibSDL.SDL_GetRenderDrawBlendMode(renderer.ptr, saved)
      LibSDL.SDL_SetRenderDrawBlendMode(renderer.ptr, LibSDL::BLENDMODE_BLEND)

      renderer.draw_color(0, 0, 0, 150)
      renderer.fill_rect(0, 0, w, h)

      pad = @size / 2
      row_h = @size + pad / 2
      widest = 0
      i = 0
      while i < @labels.length
        m = @font.measure("> " + @labels[i] + " <")
        widest = m[0] if m[0] > widest
        i += 1
      end
      tm = @title_font.measure(@title)
      hint = "UP/DOWN   ENTER: SELECT   ESC: BACK"
      hm = @hint_font.measure(hint)
      panel_w = widest + pad * 4
      panel_w = tm[0] + pad * 4 if tm[0] + pad * 4 > panel_w
      panel_w = hm[0] + pad * 2 if hm[0] + pad * 2 > panel_w
      panel_h = pad + tm[1] + pad + @labels.length * row_h + pad + hm[1] + pad
      px = (w - panel_w) / 2
      py = (h - panel_h) / 2

      renderer.draw_color(10, 12, 22, 236)
      renderer.fill_rect(px, py, panel_w, panel_h)
      renderer.draw_color(255, 214, 72, 255)
      renderer.draw_rect(px, py, panel_w, panel_h)
      renderer.draw_rect(px + 3, py + 3, panel_w - 6, panel_h - 6)

      renderer.draw_text(@title_font, @title, px + (panel_w - tm[0]) / 2, py + pad, 255, 214, 72, 255)

      @item_x = px
      @item_y = py + pad + tm[1] + pad
      @item_w = panel_w
      @item_h = row_h
      i = 0
      while i < @labels.length
        y = @item_y + i * row_h
        if i == @selected
          renderer.draw_color(255, 214, 72, 40)
          renderer.fill_rect(px + pad, y, panel_w - pad * 2, row_h)
          text = "> " + @labels[i] + " <"
          m = @font.measure(text)
          renderer.draw_text(@font, text, px + (panel_w - m[0]) / 2, y + (row_h - m[1]) / 2, 255, 255, 255, 255)
        else
          m = @font.measure(@labels[i])
          renderer.draw_text(@font, @labels[i], px + (panel_w - m[0]) / 2, y + (row_h - m[1]) / 2, 170, 176, 196, 255)
        end
        i += 1
      end
      renderer.draw_text(@hint_font, hint, px + (panel_w - hm[0]) / 2, py + panel_h - pad - hm[1], 120, 126, 146, 255)

      LibSDL.SDL_SetRenderDrawBlendMode(renderer.ptr, saved.get_value(:u32, 0))
    end

    def close_fonts
      @font.close
      @title_font.close
      @hint_font.close
    end
  end
end
