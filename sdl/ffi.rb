module LibSDL
  ffi_lib "SDL2"
  ffi_cflags "-I/opt/homebrew/include/SDL2 -L/opt/homebrew/lib"

  # Init flags
  ffi_const :INIT_VIDEO,  0x00000020
  ffi_const :INIT_EVENTS, 0x00004000

  # Window position
  ffi_const :WINDOWPOS_CENTERED,  0x2FFF0000
  ffi_const :WINDOWPOS_UNDEFINED, 0x1FFF0000

  # Window flags
  ffi_const :WINDOW_FULLSCREEN, 0x00000001
  ffi_const :WINDOW_SHOWN,      0x00000004
  ffi_const :WINDOW_BORDERLESS, 0x00000010
  ffi_const :WINDOW_RESIZABLE,  0x00000020

  # Renderer flags
  ffi_const :RENDERER_SOFTWARE,     0x00000001
  ffi_const :RENDERER_ACCELERATED,  0x00000002
  ffi_const :RENDERER_PRESENTVSYNC, 0x00000004

  # Event types
  ffi_const :QUIT,            0x100
  ffi_const :WINDOWEVENT,     0x200
  ffi_const :KEYDOWN,         0x300
  ffi_const :KEYUP,           0x301
  ffi_const :MOUSEMOTION,     0x400
  ffi_const :MOUSEBUTTONDOWN, 0x401
  ffi_const :MOUSEBUTTONUP,   0x402
  ffi_const :MOUSEWHEEL,      0x403

  # Key modifier flags
  ffi_const :KMOD_NONE,   0x0000
  ffi_const :KMOD_LSHIFT, 0x0001
  ffi_const :KMOD_RSHIFT, 0x0002
  ffi_const :KMOD_SHIFT,  0x0003
  ffi_const :KMOD_LCTRL,  0x0040
  ffi_const :KMOD_RCTRL,  0x0080
  ffi_const :KMOD_CTRL,   0x00C0
  ffi_const :KMOD_LALT,   0x0100
  ffi_const :KMOD_RALT,   0x0200
  ffi_const :KMOD_ALT,    0x0300

  # SDLK key constants (printable range maps 1:1 to ASCII)
  ffi_const :K_BACKSPACE, 8
  ffi_const :K_TAB,       9
  ffi_const :K_RETURN,    13
  ffi_const :K_ESCAPE,    27
  ffi_const :K_SPACE,     32

  # Arrow / navigation keys use SDL_SCANCODE_MASK (1<<30)
  ffi_const :K_RIGHT,  0x4000004F
  ffi_const :K_LEFT,   0x40000050
  ffi_const :K_DOWN,   0x40000051
  ffi_const :K_UP,     0x40000052

  # Function keys
  ffi_const :K_F1,  0x4000003A
  ffi_const :K_F2,  0x4000003B
  ffi_const :K_F3,  0x4000003C
  ffi_const :K_F4,  0x4000003D
  ffi_const :K_F5,  0x4000003E
  ffi_const :K_F6,  0x4000003F
  ffi_const :K_F7,  0x40000040
  ffi_const :K_F8,  0x40000041
  ffi_const :K_F9,  0x40000042
  ffi_const :K_F10, 0x40000043
  ffi_const :K_F11, 0x40000044
  ffi_const :K_F12, 0x40000045

  # Mouse buttons
  ffi_const :BUTTON_LEFT,   1
  ffi_const :BUTTON_MIDDLE, 2
  ffi_const :BUTTON_RIGHT,  3

  # Window event IDs
  ffi_const :WINDOWEVENT_RESIZED,      5
  ffi_const :WINDOWEVENT_SIZE_CHANGED, 6
  ffi_const :WINDOWEVENT_CLOSE,        14

  # Lifecycle
  ffi_func :SDL_Init,     [:int],  :int
  ffi_func :SDL_Quit,     [],      :void
  ffi_func :SDL_GetError, [],      :str

  # Window
  ffi_func :SDL_CreateWindow,   [:str, :int, :int, :int, :int, :int], :ptr
  ffi_func :SDL_DestroyWindow,  [:ptr], :void
  ffi_func :SDL_SetWindowTitle, [:ptr, :str], :void

  # Renderer
  ffi_func :SDL_CreateRenderer,     [:ptr, :int, :int], :ptr
  ffi_func :SDL_DestroyRenderer,    [:ptr], :void
  ffi_func :SDL_SetRenderDrawColor, [:ptr, :int, :int, :int, :int], :int
  ffi_func :SDL_RenderClear,        [:ptr], :int
  ffi_func :SDL_RenderPresent,      [:ptr], :void
  ffi_func :SDL_RenderDrawPoint,    [:ptr, :int, :int], :int
  ffi_func :SDL_RenderDrawLine,     [:ptr, :int, :int, :int, :int], :int

  # Timer
  ffi_func :SDL_GetTicks, [], :int
  ffi_func :SDL_Delay,    [:int], :void

  # Shim functions (see sdl/shim.c) — event access and rect helpers
  ffi_func :sdl_poll_event,      [], :int
  ffi_func :sdl_event_type,      [], :int
  ffi_func :sdl_key_sym,         [], :int
  ffi_func :sdl_key_mod,         [], :int
  ffi_func :sdl_mouse_x,         [], :int
  ffi_func :sdl_mouse_y,         [], :int
  ffi_func :sdl_mouse_button,    [], :int
  ffi_func :sdl_mouse_clicks,    [], :int
  ffi_func :sdl_wheel_x,         [], :int
  ffi_func :sdl_wheel_y,         [], :int
  ffi_func :sdl_window_event_id, [], :int
  ffi_func :sdl_render_fill_rect, [:ptr, :int, :int, :int, :int], :int
  ffi_func :sdl_render_draw_rect, [:ptr, :int, :int, :int, :int], :int
  ffi_func :sdl_get_window_width,  [:ptr], :int
  ffi_func :sdl_get_window_height, [:ptr], :int
end
