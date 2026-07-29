module SDL
  class Screen
    # Opens an SDL window + renderer, yields both, then tears everything down.
    # SDL_Init / SDL_Quit bracket the block; the renderer and window are closed
    # in the ensure clause so they're always cleaned up even on exception.
    def self.open(title, width: 800, height: 600,
                  flags: LibSDL::WINDOW_SHOWN | LibSDL::WINDOW_RESIZABLE)
      if LibSDL.SDL_Init(LibSDL::INIT_VIDEO) != 0
        Log.write("SDL_Init failed: #{LibSDL.SDL_GetError}")
        return
      end
      Log.write("SDL_Init: ok")

      window   = Window.new(title, width: width, height: height, flags: flags)
      renderer = Renderer.new(window)

      begin
        yield window, renderer
      ensure
        renderer.close
        window.close
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
