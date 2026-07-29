module SDL
  class Font
    attr_reader :ptr

    def initialize(path, size)
      @ptr = LibSDL.TTF_OpenFont(path, size.to_f)
      Log.write("TTF_OpenFont(#{path}, #{size}): #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
    end

    def close
      LibSDL.TTF_CloseFont(@ptr)
    end
  end
end
