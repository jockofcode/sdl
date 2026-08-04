module LibSDL
  ffi_lib "SDL3"
  ffi_lib "SDL3_ttf"
  # No ffi_lib "SDL3_image" — unlike SDL3/SDL3_ttf (both installed as
  # libSDL3.a/libSDL3_ttf.a, a name -lSDL3/-lSDL3_ttf can resolve),
  # SDL3_image's build script (see sdl/native/sdl3_image/build.sh) merges
  # it with its vendored libpng/zlib/libjpeg deps into one differently-named
  # archive (libSDL3_image_bundle.a) since the vendored deps' own target
  # names weren't confirmed from this environment. [native].libs below
  # already links that archive by its full ${build.out} path; ffi_lib would
  # only add a redundant, wrongly-named -lSDL3_image the linker can't
  # resolve.
  # No ffi_cflags here: with SDL3/SDL3_ttf now built by spin.toml's [[build]]
  # entries (see there), their headers only exist transiently inside each
  # entry's own scratch dir (or as tarballs under ${build.out}) — there is
  # no stable path to point a compile-time -I flag at. ffi_func declarations
  # don't need the real headers to compile (they're self-contained extern
  # prototypes); only shim.c does, and it gets its own -I flags from
  # sdl/build_shim.sh, independent of this DSL.

  # Init flags
  ffi_const :INIT_VIDEO,    0x00000020
  ffi_const :INIT_AUDIO,    0x00000010
  ffi_const :INIT_JOYSTICK, 0x00000200
  ffi_const :INIT_GAMEPAD,  0x00002000
  ffi_const :INIT_EVENTS,   0x00004000

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
  ffi_const :TEXT_EDITING,    0x302
  ffi_const :TEXT_INPUT,      0x303
  ffi_const :MOUSEMOTION,     0x400
  ffi_const :MOUSEBUTTONDOWN, 0x401
  ffi_const :MOUSEBUTTONUP,   0x402
  ffi_const :MOUSEWHEEL,      0x403

  # Window events — SDL3 flattens these to top-level event types (no more
  # SDL_WINDOWEVENT wrapper + sub-ID). Only the one this binding actually
  # uses is declared; add more EVENT_WINDOW_* as needed straight from
  # SDL_events.h's SDL_EventType enum (window events run 0x202-0x210+).
  ffi_const :EVENT_WINDOW_PIXEL_SIZE_CHANGED, 0x207

  # Gamepad events
  ffi_const :EVENT_GAMEPAD_AXIS_MOTION,  0x650
  ffi_const :EVENT_GAMEPAD_BUTTON_DOWN,  0x651
  ffi_const :EVENT_GAMEPAD_BUTTON_UP,    0x652
  ffi_const :EVENT_GAMEPAD_ADDED,        0x653
  ffi_const :EVENT_GAMEPAD_REMOVED,      0x654

  # Touch events
  ffi_const :EVENT_FINGER_DOWN,     0x700
  ffi_const :EVENT_FINGER_UP,       0x701
  ffi_const :EVENT_FINGER_MOTION,   0x702
  ffi_const :EVENT_FINGER_CANCELED, 0x703

  # Pen events — SDL_EVENT_PEN_PROXIMITY_IN/OUT (0x1300/0x1301, pen enters/
  # leaves range) aren't exposed as separate constants here; everything
  # else in the run is.
  ffi_const :EVENT_PEN_DOWN,        0x1302
  ffi_const :EVENT_PEN_UP,          0x1303
  ffi_const :EVENT_PEN_BUTTON_DOWN, 0x1304
  ffi_const :EVENT_PEN_BUTTON_UP,   0x1305
  ffi_const :EVENT_PEN_MOTION,      0x1306
  ffi_const :EVENT_PEN_AXIS,        0x1307

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

  # SDL_GamepadButton — matches SDL3's enum order exactly (SOUTH=0..
  # DPAD_RIGHT=15); the buttons past DPAD_RIGHT (MISC1, paddles, touchpad,
  # ...) aren't named here, pass their raw int if needed.
  ffi_const :GAMEPAD_BUTTON_SOUTH,          0
  ffi_const :GAMEPAD_BUTTON_EAST,           1
  ffi_const :GAMEPAD_BUTTON_WEST,           2
  ffi_const :GAMEPAD_BUTTON_NORTH,          3
  ffi_const :GAMEPAD_BUTTON_BACK,           4
  ffi_const :GAMEPAD_BUTTON_GUIDE,          5
  ffi_const :GAMEPAD_BUTTON_START,          6
  ffi_const :GAMEPAD_BUTTON_LEFT_STICK,     7
  ffi_const :GAMEPAD_BUTTON_RIGHT_STICK,    8
  ffi_const :GAMEPAD_BUTTON_LEFT_SHOULDER,  9
  ffi_const :GAMEPAD_BUTTON_RIGHT_SHOULDER, 10
  ffi_const :GAMEPAD_BUTTON_DPAD_UP,        11
  ffi_const :GAMEPAD_BUTTON_DPAD_DOWN,      12
  ffi_const :GAMEPAD_BUTTON_DPAD_LEFT,      13
  ffi_const :GAMEPAD_BUTTON_DPAD_RIGHT,     14

  # SDL_GamepadAxis — matches SDL3's enum order exactly.
  ffi_const :GAMEPAD_AXIS_LEFTX,         0
  ffi_const :GAMEPAD_AXIS_LEFTY,         1
  ffi_const :GAMEPAD_AXIS_RIGHTX,        2
  ffi_const :GAMEPAD_AXIS_RIGHTY,        3
  ffi_const :GAMEPAD_AXIS_LEFT_TRIGGER,  4
  ffi_const :GAMEPAD_AXIS_RIGHT_TRIGGER, 5

  # SDL_PenAxis — matches SDL3's enum order exactly.
  ffi_const :PEN_AXIS_PRESSURE,            0
  ffi_const :PEN_AXIS_XTILT,               1
  ffi_const :PEN_AXIS_YTILT,               2
  ffi_const :PEN_AXIS_DISTANCE,            3
  ffi_const :PEN_AXIS_ROTATION,            4
  ffi_const :PEN_AXIS_SLIDER,              5
  ffi_const :PEN_AXIS_TANGENTIAL_PRESSURE, 6

  # SDL_AudioFormat — little-endian values only (LP64 arm64/x86_64 target,
  # per ffi_spec.c's own header comment). SDL_AUDIO_S16/_F32 without an
  # LE/BE suffix resolve to these same values on a little-endian build.
  ffi_const :AUDIO_S16, 0x8010
  ffi_const :AUDIO_F32, 0x8120

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

  # Shim functions (see sdl/shim.c) — clip/scissor rect and filled-polygon
  # geometry, both needed by an immediate-mode UI's draw list (scroll-clipped
  # child regions, rounded corners, circular color pickers, ...) that plain
  # fill_rect/draw_rect can't express. fill_convex_polygon's `points` arg is
  # a flat [x0,y0,x1,y1,...] Array<Float>; its `n` companion is the element
  # count (2 * point count), not the point count — same :float_array + count
  # convention FFI.md documents for array args generally.
  ffi_func :sdl_set_render_clip_rect,   [:ptr, :int, :int, :int, :int], :int
  ffi_func :sdl_clear_render_clip_rect, [:ptr], :int
  ffi_func :sdl_fill_convex_polygon, [:ptr, :float_array, :size_t, :int, :int, :int, :int], :int

  # Shim functions (see sdl/shim.c) — text rendering
  ffi_func :sdl_ttf_render_text_blended, [:ptr, :str, :int, :int, :int, :int], :ptr
  ffi_func :sdl_get_texture_width,  [:ptr], :int
  ffi_func :sdl_get_texture_height, [:ptr], :int
  ffi_func :sdl_render_texture, [:ptr, :ptr, :int, :int, :int, :int], :int

  # Shim functions (see sdl/shim.c) — text measurement, needed for layout
  # (button auto-sizing, text wrapping, caret placement in input fields).
  ffi_func :sdl_measure_text_width,  [:ptr, :str], :int
  ffi_func :sdl_measure_text_height, [:ptr, :str], :int

  # Clipboard — SDL_SetClipboardText is a plain direct binding, but
  # SDL_GetClipboardText's malloc'd return needs sdl_get_clipboard_text's
  # copy-then-SDL_free shim wrapper (see shim.c) since Spinel's :str return
  # marshalling never frees the pointer it copies from.
  ffi_func :SDL_SetClipboardText,   [:str], :bool
  ffi_func :sdl_get_clipboard_text, [], :str

  # Text input mode — brackets IME composition / SDL_EVENT_TEXT_INPUT
  # delivery while a text field is focused; events don't fire without this.
  ffi_func :SDL_StartTextInput, [:ptr], :bool
  ffi_func :SDL_StopTextInput,  [:ptr], :bool

  # Shim function (see sdl/shim.c) — composed text for the current polled
  # SDL_EVENT_TEXT_INPUT event.
  ffi_func :sdl_text_input_text, [], :str

  # Windows — multi-window dispatch. SDL_GetWindowID lets a program match
  # its own Window objects against a polled event's window (see
  # sdl_event_window_id below).
  ffi_func :SDL_GetWindowID, [:ptr], :int

  # Shim function (see sdl/shim.c) — which window a polled event belongs
  # to; dispatches on event category internally since SDL3 doesn't expose
  # windowID through one shared union member.
  ffi_func :sdl_event_window_id, [], :int

  # Gamepad — poll/query-based, no callbacks needed. SDL_GetGamepadButton's
  # 2nd arg and SDL_GetGamepadAxis's are SDL_GamepadButton/SDL_GamepadAxis
  # enums (int-sized); pass the GAMEPAD_BUTTON_*/GAMEPAD_AXIS_* constants
  # above. SDL_GetGamepadAxis's real return type is Sint16 (-32768..32767),
  # declared :int16 to match the ABI width exactly rather than assume the
  # same wide-return safety already spiked for :bool (see the SDL3
  # migration notes on SDL_CreateRenderer above) extends to every narrow
  # return type.
  ffi_func :SDL_OpenGamepad,      [:uint32], :ptr
  ffi_func :SDL_CloseGamepad,     [:ptr],    :void
  ffi_func :SDL_GamepadConnected, [:ptr],    :bool
  ffi_func :SDL_GetGamepadName,   [:ptr],    :str
  ffi_func :SDL_GetGamepadButton, [:ptr, :int], :bool
  ffi_func :SDL_GetGamepadAxis,   [:ptr, :int], :int16
  ffi_func :SDL_RumbleGamepad,    [:ptr, :uint16, :uint16, :uint32], :bool

  # Shim functions (see sdl/shim.c) — gamepad enumeration (wraps
  # SDL_GetGamepads' int*-out-param + malloc'd-array return, which the FFI
  # DSL has no direct spec for) and gamepad event field access.
  ffi_func :sdl_gamepad_count,       [], :int
  ffi_func :sdl_gamepad_id_at,       [:int], :int
  ffi_func :sdl_gamepad_which,       [], :int
  ffi_func :sdl_gamepad_button,      [], :int
  ffi_func :sdl_gamepad_button_down, [], :int
  ffi_func :sdl_gamepad_axis,        [], :int
  ffi_func :sdl_gamepad_axis_value,  [], :int

  # Shim functions (see sdl/shim.c) — touch event fields. Real `float`
  # return type: these are normalized 0..1 / -1..1 values, not integers.
  ffi_func :sdl_touch_x,        [], :float
  ffi_func :sdl_touch_y,        [], :float
  ffi_func :sdl_touch_dx,       [], :float
  ffi_func :sdl_touch_dy,       [], :float
  ffi_func :sdl_touch_pressure, [], :float

  # Shim functions (see sdl/shim.c) — pen event fields.
  ffi_func :sdl_pen_x,            [], :float
  ffi_func :sdl_pen_y,            [], :float
  ffi_func :sdl_pen_down,         [], :int
  ffi_func :sdl_pen_eraser,       [], :int
  ffi_func :sdl_pen_button,       [], :int
  ffi_func :sdl_pen_button_down,  [], :int
  ffi_func :sdl_pen_axis,         [], :int
  ffi_func :sdl_pen_axis_value,   [], :float

  # Shim functions (see sdl/shim.c) — audio. sdl_audio_beep synthesizes and
  # queues a sine-wave tone on a lazily-opened process-lifetime stream (see
  # SDL::Audio.beep); the sdl_wav_* family loads/plays/frees a WAV file on
  # its own dedicated stream (see SDL::Sound).
  ffi_func :sdl_audio_beep,      [:int, :int, :int], :int
  ffi_func :sdl_audio_queued_ms, [], :int
  ffi_func :sdl_load_wav,        [:str], :ptr
  ffi_func :sdl_wav_play,        [:ptr], :int
  ffi_func :sdl_wav_len,         [:ptr], :int
  ffi_func :sdl_wav_free,        [:ptr], :int

  # SDL_image — IMG_Load returns a Surface (format-neutral, use
  # SDL_CreateTextureFromSurface + sdl_surface_width/height below to turn
  # it into a drawable Texture); IMG_LoadTexture is the one-step shortcut
  # straight to a Renderer-bound Texture, used by SDL::Texture.load.
  ffi_func :IMG_Load,        [:str],        :ptr
  ffi_func :IMG_LoadTexture, [:ptr, :str],  :ptr

  # Shim functions (see sdl/shim.c) — SDL_Surface's w/h field reads.
  ffi_func :sdl_surface_width,  [:ptr], :int
  ffi_func :sdl_surface_height, [:ptr], :int

  # Shim functions (see sdl/shim.c) — test-support synthetic event
  # injection (SDL_PushEvent-backed). Not part of the public binding
  # surface; used only by test/*.rb to exercise the touch/pen/gamepad
  # event-field accessors above without real hardware.
  ffi_func :sdl_test_push_touch_event, [:float, :float, :float, :float, :float], :int
  ffi_func :sdl_test_push_pen_event,   [:float, :float, :float], :int
  ffi_func :sdl_test_push_gamepad_button_event, [:int, :int], :int
  ffi_func :sdl_test_push_gamepad_axis_event,   [:int, :int], :int
end
