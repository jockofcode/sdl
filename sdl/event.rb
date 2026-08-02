module SDL
  module Event
    # Polls one pending event. Returns the event type integer if an event was
    # available, nil if the queue was empty. After a non-nil return, the type
    # and field accessors reflect the polled event until the next call.
    def self.poll
      return nil if LibSDL.sdl_poll_event == 0
      LibSDL.sdl_event_type
    end

    def self.type
      LibSDL.sdl_event_type
    end

    # Key event fields
    def self.key_sym
      LibSDL.sdl_key_sym
    end

    def self.key_mod
      LibSDL.sdl_key_mod
    end

    def self.shift?
      (LibSDL.sdl_key_mod & LibSDL::KMOD_SHIFT) != 0
    end

    def self.ctrl?
      (LibSDL.sdl_key_mod & LibSDL::KMOD_CTRL) != 0
    end

    def self.alt?
      (LibSDL.sdl_key_mod & LibSDL::KMOD_ALT) != 0
    end

    # Mouse event fields
    def self.mouse_x
      LibSDL.sdl_mouse_x
    end

    def self.mouse_y
      LibSDL.sdl_mouse_y
    end

    def self.mouse_button
      LibSDL.sdl_mouse_button
    end

    def self.mouse_clicks
      LibSDL.sdl_mouse_clicks
    end

    # Mouse wheel fields
    def self.wheel_x
      LibSDL.sdl_wheel_x
    end

    def self.wheel_y
      LibSDL.sdl_wheel_y
    end

    # Which window this event belongs to (SDL_WindowID) — matches
    # SDL::Window#id. Multi-window programs use this to route a polled
    # event to the right Window/Renderer pair.
    def self.window_id
      LibSDL.sdl_event_window_id
    end

    # Gamepad event fields
    def self.gamepad_which
      LibSDL.sdl_gamepad_which
    end

    def self.gamepad_button
      LibSDL.sdl_gamepad_button
    end

    def self.gamepad_button_down?
      LibSDL.sdl_gamepad_button_down != 0
    end

    def self.gamepad_axis
      LibSDL.sdl_gamepad_axis
    end

    def self.gamepad_axis_value
      LibSDL.sdl_gamepad_axis_value
    end

    # Touch event fields — x/y normalized 0..1, dx/dy normalized -1..1,
    # pressure normalized 0..1.
    def self.touch_x
      LibSDL.sdl_touch_x
    end

    def self.touch_y
      LibSDL.sdl_touch_y
    end

    def self.touch_dx
      LibSDL.sdl_touch_dx
    end

    def self.touch_dy
      LibSDL.sdl_touch_dy
    end

    def self.touch_pressure
      LibSDL.sdl_touch_pressure
    end

    # Pen event fields — x/y are window-relative pixel coordinates.
    def self.pen_x
      LibSDL.sdl_pen_x
    end

    def self.pen_y
      LibSDL.sdl_pen_y
    end

    def self.pen_down?
      LibSDL.sdl_pen_down != 0
    end

    def self.pen_eraser?
      LibSDL.sdl_pen_eraser != 0
    end

    def self.pen_button
      LibSDL.sdl_pen_button
    end

    def self.pen_button_down?
      LibSDL.sdl_pen_button_down != 0
    end

    def self.pen_axis
      LibSDL.sdl_pen_axis
    end

    def self.pen_axis_value
      LibSDL.sdl_pen_axis_value
    end
  end
end
