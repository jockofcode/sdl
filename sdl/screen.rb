module SDL
  class Screen
    # Opens an SDL window + renderer, yields both, then tears everything down.
    # SDL_Init / SDL_Quit bracket the block; the renderer and window are closed
    # in the ensure clause so they're always cleaned up even on exception.
    def self.open(title, width: 800, height: 600,
                  flags: LibSDL::WINDOW_RESIZABLE)
      # GAMEPAD implies JOYSTICK; AUDIO opens no device by itself (that
      # happens lazily on first SDL::Audio.beep / SDL::Sound.new call) but
      # still needs the subsystem initialized up front.
      init_flags = LibSDL::INIT_VIDEO | LibSDL::INIT_GAMEPAD | LibSDL::INIT_AUDIO
      unless LibSDL.SDL_Init(init_flags)
        Log.write("SDL_Init failed: #{LibSDL.SDL_GetError}")
        return
      end
      Log.write("SDL_Init: ok")

      unless LibSDL.TTF_Init
        Log.write("TTF_Init failed: #{LibSDL.SDL_GetError}")
        LibSDL.SDL_Quit
        return
      end
      Log.write("TTF_Init: ok")

      window   = Window.new(title, width: width, height: height, flags: flags)
      renderer = Renderer.new(window)

      begin
        yield window, renderer
      ensure
        renderer.close
        window.close
        LibSDL.TTF_Quit
        Log.write("TTF_Quit: done")
        LibSDL.SDL_Quit
        Log.write("SDL_Quit: done")
        Log.close
      end
    end

    def self.ticks
      LibSDL.SDL_GetTicks
    end

    def self.delay(ms)
      LibSDL.SDL_Delay(ms)
    end
  end
end
