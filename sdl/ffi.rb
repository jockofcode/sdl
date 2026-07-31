module LibSDL
  ffi_lib "SDL3"
  ffi_lib "SDL3_ttf"
  # No ffi_cflags here: with SDL3/SDL3_ttf now built by spin.toml's [[build]]
  # entries (see there), their headers only exist transiently inside each
  # entry's own scratch dir (or as tarballs under ${build.out}) — there is
  # no stable path to point a compile-time -I flag at. ffi_func declarations
  # don't need the real headers to compile (they're self-contained extern
  # prototypes); only shim.c does, and it gets its own -I flags from
  # sdl/build_shim.sh, independent of this DSL.

  # Init flags
  ffi_const :INIT_VIDEO,  0x00000020
  ffi_const :INIT_EVENTS, 0x00004000

  # Window position
  ffi_const :WINDOWPOS_CENTERED,  0x2FFF0000
  ffi_const :WINDOWPOS_UNDEFINED, 0x1FFF0000

  # Window flags
  ffi_const :WINDOW_FULLSCREEN, 0x00000001
  ffi_const :WINDOW_BORDERLESS, 0x00000010
  ffi_const :WINDOW_RESIZABLE,  0x00000020

  # Event types
  ffi_const :QUIT,            0x100
  ffi_const :KEYDOWN,         0x300
  ffi_const :KEYUP,           0x301
  ffi_const :MOUSEMOTION,     0x400
  ffi_const :MOUSEBUTTONDOWN, 0x401
  ffi_const :MOUSEBUTTONUP,   0x402
  ffi_const :MOUSEWHEEL,      0x403

  # Window events — SDL3 flattens these to top-level event types (no more
  # SDL_WINDOWEVENT wrapper + sub-ID). Only the one this binding actually
  # uses is declared; add more EVENT_WINDOW_* as needed straight from
  # SDL_events.h's SDL_EventType enum (window events run 0x202-0x210+).
  ffi_const :EVENT_WINDOW_PIXEL_SIZE_CHANGED, 0x207

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

  # SDLK key constants (printable range maps 1:1 to ASCII) — unchanged values in SDL3
  ffi_const :K_BACKSPACE, 8
  ffi_const :K_TAB,       9
  ffi_const :K_RETURN,    13
  ffi_const :K_ESCAPE,    27
  ffi_const :K_SPACE,     32

  # Arrow / navigation keys use SDL_SCANCODE_MASK (1<<30) — unchanged values in SDL3
  ffi_const :K_RIGHT,  0x4000004F
  ffi_const :K_LEFT,   0x40000050
  ffi_const :K_DOWN,   0x40000051
  ffi_const :K_UP,     0x40000052

  # Function keys — unchanged values in SDL3
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

  # Lifecycle — SDL_Init/error-returning render & window calls now return
  # real bool (spiked and confirmed safe to declare :bool — see
  # SDL3_MIGRATION_PLAN.md)
  ffi_func :SDL_Init,     [:int],  :bool
  ffi_func :SDL_Quit,     [],      :void
  ffi_func :SDL_GetError, [],      :str

  # Window — SDL_CreateWindow dropped its x/y params in SDL3; center (or
  # position) the window afterward with SDL_SetWindowPosition. Window flags
  # are Uint64 now, so the flags arg uses :long rather than :int.
  ffi_func :SDL_CreateWindow,     [:str, :int, :int, :long], :ptr
  ffi_func :SDL_SetWindowPosition, [:ptr, :int, :int], :bool
  ffi_func :SDL_DestroyWindow,    [:ptr], :void
  ffi_func :SDL_SetWindowTitle,   [:ptr, :str], :bool

  # Renderer — SDL_CreateRenderer dropped its flags param and its 2nd arg
  # is now a driver-name string (NULL/nil = auto-pick), not an index.
  # VSync is a separate post-creation call in SDL3, not a creation flag.
  ffi_func :SDL_CreateRenderer,     [:ptr, :ptr], :ptr
  ffi_func :SDL_SetRenderVSync,     [:ptr, :int], :bool
  ffi_func :SDL_DestroyRenderer,    [:ptr], :void
  ffi_func :SDL_SetRenderDrawColor, [:ptr, :int, :int, :int, :int], :bool
  ffi_func :SDL_RenderClear,        [:ptr], :bool
  ffi_func :SDL_RenderPresent,      [:ptr], :bool
  # Renamed from SDL_RenderDrawPoint/Line in SDL2; coordinates are float now.
  ffi_func :SDL_RenderPoint, [:ptr, :float, :float], :bool
  ffi_func :SDL_RenderLine,  [:ptr, :float, :float, :float, :float], :bool

  # Timer — SDL_GetTicks returns Uint64 now (was Uint32); :int here would
  # silently truncate after ~35 minutes of uptime, so this must be :long.
  ffi_func :SDL_GetTicks, [], :long
  ffi_func :SDL_Delay,    [:int], :void

  # SDL_ttf — font loading + text rendering. TTF_Init/TTF_Quit bracket
  # library use the same way SDL_Init/SDL_Quit do.
  ffi_func :TTF_Init,      [],                :bool
  ffi_func :TTF_Quit,      [],                :void
  ffi_func :TTF_OpenFont,  [:str, :float],    :ptr
  ffi_func :TTF_CloseFont, [:ptr],            :void

  # Shim function (see sdl/shim.c) — opens one of the fonts embedded into
  # this binary by build_shim.sh, with no filesystem path involved. See
  # SDL::Font.bundled and the README's "Fonts and portability" section.
  ffi_func :sdl_open_bundled_font, [:str, :float], :ptr

  # Surface -> texture handoff for rendering rasterized text.
  ffi_func :SDL_CreateTextureFromSurface, [:ptr, :ptr], :ptr
  ffi_func :SDL_DestroySurface,           [:ptr],       :void
  ffi_func :SDL_DestroyTexture,           [:ptr],       :void

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
  ffi_func :sdl_render_fill_rect, [:ptr, :int, :int, :int, :int], :int
  ffi_func :sdl_render_draw_rect, [:ptr, :int, :int, :int, :int], :int
  ffi_func :sdl_get_window_width,  [:ptr], :int
  ffi_func :sdl_get_window_height, [:ptr], :int

  # Shim functions (see sdl/shim.c) — text rendering
  ffi_func :sdl_ttf_render_text_blended, [:ptr, :str, :int, :int, :int, :int], :ptr
  ffi_func :sdl_get_texture_width,  [:ptr], :int
  ffi_func :sdl_get_texture_height, [:ptr], :int
  ffi_func :sdl_render_texture, [:ptr, :ptr, :int, :int, :int, :int], :int
end
