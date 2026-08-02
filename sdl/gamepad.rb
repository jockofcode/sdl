module SDL
  class Gamepad
    attr_reader :ptr

    # Number of gamepads currently connected (SDL_GetGamepads' count).
    def self.count
      LibSDL.sdl_gamepad_count
    end

    # Opens the gamepad at the given SDL_GetGamepads() enumeration index
    # (0-based, NOT a joystick instance ID) — returns nil if index is out
    # of range.
    def self.open(index)
      id = LibSDL.sdl_gamepad_id_at(index)
      return nil if id == 0
      new(id)
    end

    def initialize(instance_id)
      @ptr = LibSDL.SDL_OpenGamepad(instance_id)
      Log.write("SDL_OpenGamepad(#{instance_id}): #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
    end

    def connected?
      LibSDL.SDL_GamepadConnected(@ptr)
    end

    def name
      LibSDL.SDL_GetGamepadName(@ptr)
    end

    # button: one of LibSDL::GAMEPAD_BUTTON_*
    def button(button)
      LibSDL.SDL_GetGamepadButton(@ptr, button)
    end

    # axis: one of LibSDL::GAMEPAD_AXIS_* — returns -32768..32767
    # (triggers are 0..32767).
    def axis(axis)
      LibSDL.SDL_GetGamepadAxis(@ptr, axis)
    end

    # low/high: 0..65535 motor strength. duration_ms: how long to rumble.
    def rumble(low: 0, high: 0, duration_ms: 200)
      LibSDL.SDL_RumbleGamepad(@ptr, low, high, duration_ms)
    end

    def close
      LibSDL.SDL_CloseGamepad(@ptr)
      Log.write("SDL_CloseGamepad: done")
    end
  end
end
