module SDL
  # Named arcade controls merged from the keyboard and one gamepad, so a
  # game asks "is fire held?" instead of matching keysyms and button ids.
  #
  #   controls = SDL::Controls.new            # opens gamepad 0 if present
  #   controls.bind_key(:fire, LibSDL::K_UP)  # extra bindings on top of the defaults
  #   loop do
  #     controls.begin_frame                  # clears the pressed/released edges
  #     while (event_type = SDL::Event.poll)
  #       controls.handle(event_type)         # true if the event mapped to an action
  #       ...                                 # the game still sees every event
  #     end
  #     game.move(controls.dir_x, controls.dir_y)
  #     game.fire if controls.pressed?(:fire)
  #   end
  #
  # Actions: :left :right :up :down :fire :alt :start :back :pause.
  # Defaults — keyboard: arrows / WASD, Space, X / Z / Shift, Enter, Esc, P.
  # Gamepad: d-pad and left stick, South (A), East or West (B / X), Start,
  # Back, Guide. Edges come from events (so a key's OS auto-repeat counts as
  # repeated presses, and the gamepad's four directions auto-repeat after a
  # short delay — handy for menus). Level state (held?, dir_x, axis_x) is
  # recomputed from what is currently down, so pressing two keys bound to
  # the same action and releasing one keeps it held.
  class Controls
    LEFT  = 0
    RIGHT = 1
    UP    = 2
    DOWN  = 3
    FIRE  = 4
    ALT   = 5
    START = 6
    BACK  = 7
    PAUSE = 8
    COUNT = 9
    ACTIONS = [:left, :right, :up, :down, :fire, :alt, :start, :back, :pause]

    DEADZONE        = 0.35    # stick travel (0..1) that counts as a direction
    RELEASE_ZONE    = 0.25    # ...and where that direction lets go again
    REPEAT_DELAY_MS = 320.0   # gamepad direction auto-repeat: first repeat
    REPEAT_MS       = 110.0   # ...and the interval after that

    K_LSHIFT = 0x400000E1
    K_RSHIFT = 0x400000E5

    attr_reader :player, :stick_x, :stick_y

    # player: which gamepad (SDL enumeration index) this instance listens to.
    # gamepad: false skips opening one — events from any pad are then
    # accepted, which is what the tests rely on.
    # repeat: gamepad direction auto-repeat on/off.
    def initialize(player: 0, gamepad: true, repeat: true)
      @player = player
      @want_pad = gamepad
      @repeat = repeat
      @pad = nil
      @pad_id = -1
      @bind_keys = []
      @bind_key_actions = []
      @bind_buttons = []
      @bind_button_actions = []
      @keys_down = {}
      @buttons_down = {}
      @pressed = []
      @released = []
      @repeat_at = []
      i = 0
      while i < COUNT
        @pressed << false
        @released << false
        @repeat_at << 0.0
        i += 1
      end
      @stick_x = 0.0
      @stick_y = 0.0
      @stick_dir_x = 0
      @stick_dir_y = 0
      default_bindings
      open_gamepad if gamepad
    end

    # ---- Bindings ----

    def action_id(action)
      case action
      when :left  then LEFT
      when :right then RIGHT
      when :up    then UP
      when :down  then DOWN
      when :fire  then FIRE
      when :alt   then ALT
      when :start then START
      when :back  then BACK
      when :pause then PAUSE
      else -1
      end
    end

    def bind_key(action, key)
      a = action_id(action)
      return if a < 0
      @bind_keys << key
      @bind_key_actions << a
    end

    def bind_button(action, button)
      a = action_id(action)
      return if a < 0
      @bind_buttons << button
      @bind_button_actions << a
    end

    def clear_keys(action)
      a = action_id(action)
      keys = []
      acts = []
      i = 0
      while i < @bind_keys.length
        if @bind_key_actions[i] != a
          keys << @bind_keys[i]
          acts << @bind_key_actions[i]
        end
        i += 1
      end
      @bind_keys = keys
      @bind_key_actions = acts
    end

    def clear_buttons(action)
      a = action_id(action)
      buttons = []
      acts = []
      i = 0
      while i < @bind_buttons.length
        if @bind_button_actions[i] != a
          buttons << @bind_buttons[i]
          acts << @bind_button_actions[i]
        end
        i += 1
      end
      @bind_buttons = buttons
      @bind_button_actions = acts
    end

    def default_bindings
      bind_key(:left, LibSDL::K_LEFT)
      bind_key(:left, "a".ord)
      bind_key(:right, LibSDL::K_RIGHT)
      bind_key(:right, "d".ord)
      bind_key(:up, LibSDL::K_UP)
      bind_key(:up, "w".ord)
      bind_key(:down, LibSDL::K_DOWN)
      bind_key(:down, "s".ord)
      bind_key(:fire, LibSDL::K_SPACE)
      bind_key(:alt, "x".ord)
      bind_key(:alt, "z".ord)
      bind_key(:alt, K_LSHIFT)
      bind_key(:alt, K_RSHIFT)
      bind_key(:start, LibSDL::K_RETURN)
      bind_key(:back, LibSDL::K_ESCAPE)
      bind_key(:pause, "p".ord)
      bind_button(:left, LibSDL::GAMEPAD_BUTTON_DPAD_LEFT)
      bind_button(:right, LibSDL::GAMEPAD_BUTTON_DPAD_RIGHT)
      bind_button(:up, LibSDL::GAMEPAD_BUTTON_DPAD_UP)
      bind_button(:down, LibSDL::GAMEPAD_BUTTON_DPAD_DOWN)
      bind_button(:fire, LibSDL::GAMEPAD_BUTTON_SOUTH)
      bind_button(:alt, LibSDL::GAMEPAD_BUTTON_EAST)
      bind_button(:alt, LibSDL::GAMEPAD_BUTTON_WEST)
      bind_button(:start, LibSDL::GAMEPAD_BUTTON_START)
      bind_button(:back, LibSDL::GAMEPAD_BUTTON_BACK)
      bind_button(:pause, LibSDL::GAMEPAD_BUTTON_GUIDE)
    end

    # ---- Gamepad lifecycle ----

    def open_gamepad
      return unless @pad.nil?
      pad = SDL::Gamepad.open(@player)
      return if pad.nil?
      @pad = pad
      @pad_id = pad.id
      Log.write("Controls: player #{@player} using gamepad #{pad.name}")
    end

    def drop_gamepad
      return if @pad.nil?
      @pad.close
      @pad = nil
      @pad_id = -1
      @buttons_down = {}
      @stick_x = 0.0
      @stick_y = 0.0
      @stick_dir_x = 0
      @stick_dir_y = 0
    end

    def gamepad?
      !@pad.nil?
    end

    def gamepad_name
      @pad.nil? ? "" : @pad.name
    end

    # strength 0.0..1.0 on both motors; silently does nothing without a pad.
    def rumble(strength = 0.5, duration_ms = 120)
      return if @pad.nil?
      v = (strength * 65535.0).to_i
      v = 0 if v < 0
      v = 65535 if v > 65535
      @pad.rumble(low: v, high: v, duration_ms: duration_ms)
    end

    def close
      drop_gamepad
    end

    # ---- Per-frame flow ----

    # Call once per frame before polling events.
    def begin_frame
      now = SDL::Screen.ticks.to_f
      i = 0
      while i < COUNT
        @pressed[i] = false
        @released[i] = false
        i += 1
      end
      return unless @repeat
      a = 0
      while a < 4
        if pad_dir_held?(a) && now >= @repeat_at[a]
          @pressed[a] = true
          @repeat_at[a] = now + REPEAT_MS
        end
        a += 1
      end
    end

    # Feed every event from SDL::Event.poll. Returns true when the event
    # mapped to one of this instance's actions (or was this pad's axis /
    # hotplug event), false for anything the game should look at itself.
    def handle(event_type)
      if event_type == LibSDL::KEYDOWN
        key = SDL::Event.key_sym
        @keys_down[key] = true
        hit = false
        i = 0
        while i < @bind_keys.length
          if @bind_keys[i] == key
            @pressed[@bind_key_actions[i]] = true
            hit = true
          end
          i += 1
        end
        return hit
      elsif event_type == LibSDL::KEYUP
        key = SDL::Event.key_sym
        @keys_down[key] = false
        hit = false
        i = 0
        while i < @bind_keys.length
          if @bind_keys[i] == key
            @released[@bind_key_actions[i]] = true
            hit = true
          end
          i += 1
        end
        return hit
      elsif event_type == LibSDL::EVENT_GAMEPAD_BUTTON_DOWN || event_type == LibSDL::EVENT_GAMEPAD_BUTTON_UP
        return false unless mine?(SDL::Event.gamepad_which)
        button = SDL::Event.gamepad_button
        down = event_type == LibSDL::EVENT_GAMEPAD_BUTTON_DOWN
        @buttons_down[button] = down
        hit = false
        i = 0
        while i < @bind_buttons.length
          if @bind_buttons[i] == button
            a = @bind_button_actions[i]
            if down
              @pressed[a] = true
              @repeat_at[a] = SDL::Screen.ticks.to_f + REPEAT_DELAY_MS if a < 4
            else
              @released[a] = true
            end
            hit = true
          end
          i += 1
        end
        return hit
      elsif event_type == LibSDL::EVENT_GAMEPAD_AXIS_MOTION
        return false unless mine?(SDL::Event.gamepad_which)
        axis = SDL::Event.gamepad_axis
        v = SDL::Event.gamepad_axis_value.to_f / 32767.0
        v = -1.0 if v < -1.0
        v = 1.0 if v > 1.0
        if axis == LibSDL::GAMEPAD_AXIS_LEFTX
          @stick_x = v
          @stick_dir_x = stick_step(@stick_dir_x, v, LEFT, RIGHT)
          return true
        elsif axis == LibSDL::GAMEPAD_AXIS_LEFTY
          @stick_y = v
          @stick_dir_y = stick_step(@stick_dir_y, v, UP, DOWN)
          return true
        end
        return false
      elsif event_type == LibSDL::EVENT_GAMEPAD_ADDED
        open_gamepad if @want_pad
        return true
      elsif event_type == LibSDL::EVENT_GAMEPAD_REMOVED
        drop_gamepad if @pad_id != -1 && SDL::Event.gamepad_which == @pad_id
        return true
      end
      false
    end

    # ---- Queries ----

    def pressed?(action)
      a = action_id(action)
      a < 0 ? false : @pressed[a]
    end

    def released?(action)
      a = action_id(action)
      a < 0 ? false : @released[a]
    end

    def held?(action)
      a = action_id(action)
      return false if a < 0
      return true if bound_down?(a)
      return true if a == LEFT && @stick_dir_x < 0
      return true if a == RIGHT && @stick_dir_x > 0
      return true if a == UP && @stick_dir_y < 0
      return true if a == DOWN && @stick_dir_y > 0
      false
    end

    # -1, 0 or 1; down and right are positive.
    def dir_x
      (held?(:right) ? 1 : 0) - (held?(:left) ? 1 : 0)
    end

    def dir_y
      (held?(:down) ? 1 : 0) - (held?(:up) ? 1 : 0)
    end

    # -1.0..1.0: full deflection for keys and the d-pad, proportional
    # (deadzone removed) for the stick.
    def axis_x
      d = (bound_down?(RIGHT) ? 1 : 0) - (bound_down?(LEFT) ? 1 : 0)
      return d.to_f if d != 0
      @stick_dir_x == 0 ? 0.0 : scaled(@stick_x)
    end

    def axis_y
      d = (bound_down?(DOWN) ? 1 : 0) - (bound_down?(UP) ? 1 : 0)
      return d.to_f if d != 0
      @stick_dir_y == 0 ? 0.0 : scaled(@stick_y)
    end

    # ---- Internals ----

    def mine?(which)
      @pad_id == -1 || which == @pad_id
    end

    # Any bound key or button currently down (not the stick).
    def bound_down?(a)
      i = 0
      while i < @bind_keys.length
        return true if @bind_key_actions[i] == a && @keys_down[@bind_keys[i]] == true
        i += 1
      end
      i = 0
      while i < @bind_buttons.length
        return true if @bind_button_actions[i] == a && @buttons_down[@bind_buttons[i]] == true
        i += 1
      end
      false
    end

    # Direction held through the gamepad only (d-pad or stick) — these
    # are the ones that auto-repeat.
    def pad_dir_held?(a)
      i = 0
      while i < @bind_buttons.length
        return true if @bind_button_actions[i] == a && @buttons_down[@bind_buttons[i]] == true
        i += 1
      end
      return true if a == LEFT && @stick_dir_x < 0
      return true if a == RIGHT && @stick_dir_x > 0
      return true if a == UP && @stick_dir_y < 0
      return true if a == DOWN && @stick_dir_y > 0
      false
    end

    # New digital direction for a stick axis, with hysteresis, raising the
    # pressed / released edges when it changes.
    def stick_step(old, v, neg_action, pos_action)
      dir = 0
      if v <= 0.0 - DEADZONE
        dir = -1
      elsif v >= DEADZONE
        dir = 1
      elsif old != 0 && v.abs > RELEASE_ZONE
        dir = old
      end
      return old if dir == old
      if old != 0
        @released[old < 0 ? neg_action : pos_action] = true
      end
      if dir != 0
        a = dir < 0 ? neg_action : pos_action
        @pressed[a] = true
        @repeat_at[a] = SDL::Screen.ticks.to_f + REPEAT_DELAY_MS
      end
      dir
    end

    def scaled(v)
      m = v.abs
      return 0.0 if m <= DEADZONE
      s = (m - DEADZONE) / (1.0 - DEADZONE)
      s = 1.0 if s > 1.0
      v < 0.0 ? 0.0 - s : s
    end
  end
end
