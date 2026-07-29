require "sdl"

# Verify event types, key codes, and flag constants match SDL3 ABI values.
puts LibSDL::INIT_VIDEO
puts LibSDL::INIT_EVENTS
puts LibSDL::WINDOWPOS_CENTERED
puts LibSDL::WINDOWPOS_UNDEFINED
puts LibSDL::WINDOW_RESIZABLE
puts LibSDL::EVENT_WINDOW_PIXEL_SIZE_CHANGED
puts LibSDL::QUIT
puts LibSDL::KEYDOWN
puts LibSDL::KEYUP
puts LibSDL::MOUSEMOTION
puts LibSDL::MOUSEBUTTONDOWN
puts LibSDL::K_ESCAPE
puts LibSDL::K_RETURN
puts LibSDL::K_UP
puts LibSDL::K_DOWN
puts LibSDL::K_LEFT
puts LibSDL::K_RIGHT
puts LibSDL::BUTTON_LEFT
puts LibSDL::BUTTON_RIGHT
