module SDL
  module Clipboard
    def self.get
      LibSDL.sdl_get_clipboard_text
    end

    def self.set(text)
      LibSDL.SDL_SetClipboardText(text)
    end
  end
end
