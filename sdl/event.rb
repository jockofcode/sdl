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
  end
end
