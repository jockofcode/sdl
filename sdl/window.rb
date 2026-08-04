module SDL
  class Window
    attr_reader :ptr

    def initialize(title, x: LibSDL::WINDOWPOS_CENTERED, y: LibSDL::WINDOWPOS_CENTERED,
                   width: 800, height: 600, flags: LibSDL::WINDOW_RESIZABLE)
      @ptr = LibSDL.SDL_CreateWindow(title, width, height, flags)
      Log.write("SDL_CreateWindow: #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
      # SDL3 dropped x/y from window creation — position it separately.
      LibSDL.SDL_SetWindowPosition(@ptr, x, y) unless @ptr == nil
    end

    def width
      LibSDL.sdl_get_window_width(@ptr)
    end

    def height
      LibSDL.sdl_get_window_height(@ptr)
    end

    def title=(str)
      LibSDL.SDL_SetWindowTitle(@ptr, str)
    end

    # SDL_WindowID — matches SDL::Event.window_id on a polled event, for
    # dispatching events across multiple open windows (see the README's
    # multi-window section; SDL::Screen.open only ever opens one).
    def id
      LibSDL.SDL_GetWindowID(@ptr)
    end

    # Begins IME composition / SDL_EVENT_TEXT_INPUT delivery for this
    # window — an InputText-style widget must call this while focused (and
    # stop_text_input when it loses focus), or text-input events never
    # fire and typed characters can only be recovered from raw key events.
    def start_text_input
      LibSDL.SDL_StartTextInput(@ptr)
    end

    def stop_text_input
      LibSDL.SDL_StopTextInput(@ptr)
    end

    def close
      LibSDL.SDL_DestroyWindow(@ptr)
      Log.write("SDL_DestroyWindow: done")
    end
  end
end
