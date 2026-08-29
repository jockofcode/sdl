# sdl

SDL3 graphics bindings for [Spinel](https://github.com/matz/spinel), an ahead-of-time Ruby compiler.

Uses Spinel's built-in FFI DSL (`ffi_lib`, `ffi_func`, `ffi_const`) — no external gems required.

## Requirements

- Spinel (`spin`)
- SDL3, SDL3_ttf, and SDL3_image (PNG/JPEG + the dependency-free formats — see `sdl/native/sdl3_image/build.sh`), all statically linked from source (see `spin.toml`'s `[[build]]`/`[native]` sections) — no `brew install` needed at build or run time, the compiled binaries have no SDL dylib dependency

The first build compiles a small C shim against SDL3. Spin will prompt you to allow it — answer `always` to permanently trust it, or run `spin trust sdl` beforehand to skip the prompt entirely.

## Usage

Create a new project and add sdl as a dependency:

```sh
mkdir myapp && cd myapp
spin init
spin add sdl --git https://github.com/jockofcode/sdl
```

Put your program in `bin/hello.rb`:

```ruby
require "sdl"

SDL::Screen.open("My Window", width: 800, height: 600) do |window, renderer|
  running = true
  while running
    while (event = SDL::Event.poll)
      running = false if event == LibSDL::QUIT
      running = false if event == LibSDL::KEYDOWN && SDL::Event.key_sym == LibSDL::K_ESCAPE
    end

    renderer.draw_color(0, 0, 0)
    renderer.clear
    renderer.draw_color(255, 80, 0)
    renderer.fill_rect(100, 100, 200, 150)
    renderer.present

    SDL::Screen.delay(16)
  end
end
```

Build and run:

```sh
spin run hello          # build + run in one step
```

Or build first and run the binary directly:

```sh
spin build
./build/bin/hello
```

## API

### `SDL::Screen`

The entry point. Always use the block form — it handles `SDL_Init`/`SDL_Quit` and resource cleanup.

```ruby
SDL::Screen.open("Title", width: 800, height: 600) do |window, renderer|
  SDL::Screen.ticks      # milliseconds since SDL_Init (SDL_GetTicks)
  SDL::Screen.delay(ms)  # pause for ms milliseconds (SDL_Delay)
end
```

The `flags:` keyword accepts any combination of `LibSDL::WINDOW_*` constants and defaults to `WINDOW_RESIZABLE` (windows are shown by default in SDL3 — there's no `WINDOW_SHOWN` flag anymore).

### `SDL::Window`

Wraps an `SDL_Window*`. Received as the first block argument from `Screen.open`.

```ruby
window.width         # current width in pixels
window.height        # current height in pixels
window.title = str   # update the window title bar
window.ptr           # raw SDL_Window* for advanced use
```

### `SDL::Renderer`

Wraps an `SDL_Renderer*`. Received as the second block argument from `Screen.open`.

```ruby
renderer.draw_color(r, g, b, a = 255)      # set current draw color
renderer.clear                              # fill with current draw color
renderer.present                            # flip to screen

renderer.draw_point(x, y)                  # draw a single pixel
renderer.draw_line(x1, y1, x2, y2)         # draw a line
renderer.fill_rect(x, y, w, h)             # draw a filled rectangle
renderer.draw_rect(x, y, w, h)             # draw a rectangle outline

renderer.ptr                               # raw SDL_Renderer* for advanced use
```

### `SDL::Event`

Polls events and exposes fields from the last polled event.

```ruby
# In your main loop — call until nil to drain the queue each frame
while (event_type = SDL::Event.poll)
  case event_type
  when LibSDL::QUIT
    # window closed
  when LibSDL::KEYDOWN, LibSDL::KEYUP
    SDL::Event.key_sym   # SDLK_* key code (integer)
    SDL::Event.key_mod   # modifier bitmask
    SDL::Event.shift?    # true if shift held
    SDL::Event.ctrl?     # true if ctrl held
    SDL::Event.alt?      # true if alt held
  when LibSDL::MOUSEMOTION
    SDL::Event.mouse_x
    SDL::Event.mouse_y
  when LibSDL::MOUSEBUTTONDOWN, LibSDL::MOUSEBUTTONUP
    SDL::Event.mouse_x
    SDL::Event.mouse_y
    SDL::Event.mouse_button   # LibSDL::BUTTON_LEFT / BUTTON_MIDDLE / BUTTON_RIGHT
    SDL::Event.mouse_clicks   # 1 = single, 2 = double
  when LibSDL::MOUSEWHEEL
    SDL::Event.wheel_x
    SDL::Event.wheel_y
  when LibSDL::EVENT_WINDOW_PIXEL_SIZE_CHANGED
    # SDL3 gives every window event its own top-level type — no more
    # SDL_WINDOWEVENT wrapper + sub-ID. Add more LibSDL::EVENT_WINDOW_*
    # constants straight from SDL_events.h as needed.
    window.width
    window.height
  end
end
```

### `SDL::Color`

Named color constants as `[r, g, b, a]` arrays, ready to splat into `draw_color`.

```ruby
renderer.draw_color(*SDL::Color::RED)
renderer.draw_color(*SDL::Color::WHITE)
```

Available colors: `BLACK WHITE RED GREEN BLUE YELLOW CYAN MAGENTA ORANGE GRAY`

### `SDL::Font`

```ruby
renderer.draw_text(font, "Score: 0", 8, 4, 255, 255, 255, 255)
```

Two ways to load one:

```ruby
# 1. One of sdl's own bundled fonts (SDL::Fonts), loaded from bytes
#    compiled directly into the binary -- no filesystem path involved.
font = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 28)
# SDL::Fonts::PUBLIC_SANS_NAME / ::JETBRAINS_MONO_NAME also available.

# 2. Any font file at a path you supply yourself.
font = SDL::Font.new("/absolute/path/to/font.ttf", 28)

font.close   # call once you're done with it (e.g. after Screen.open's block)
```

**Prefer `SDL::Font.bundled` over building a path with `__dir__`.** Spinel's
`__dir__` is a *compile-time* literal of the source file's directory on the
machine that ran `spin build` — it is not derived from the running
executable's location at runtime. A path like
`File.join(__dir__, "..", "assets", "fonts", "whatever.ttf")` bakes in that
build machine's absolute path, so it keeps working as long as you run the
binary from the same checkout on the same machine, but breaks silently the
moment you copy the compiled binary anywhere else (another machine, a
`dist/` folder, a released artifact) — `TTF_OpenFont` returns `NULL` for
the missing path, and `renderer.draw_text` just quietly draws nothing, with
every other graphic (which has no file dependency) rendering fine. If your
app needs its own custom font rather than one of sdl's bundled ones, embed
it the same way sdl embeds its own (see `sdl/bin2c.c` and
`build_shim.sh` for the pattern: convert the `.ttf` into a compiled-in byte
array in your own `[[build]]` step, then open it via `SDL_IOFromConstMem` +
`TTF_OpenFontIO` through your own small FFI shim) rather than shipping the
font file alongside the binary and hoping the path holds up.

### `SDL::Texture` (images — SDL_image)

```ruby
texture = SDL::Texture.load(renderer, "/absolute/path/to/image.png")
# BMP, GIF, PNM, XCF, XPM, PCX, LBM, QOI, TGA, SVG decode with no external
# dependency; PNG and JPEG are vendored in (libpng/libjpeg built from
# source — see sdl/native/sdl3_image/build.sh). AVIF/WEBP/TIFF/JXL are off.

renderer.draw_texture(texture, x, y)               # native pixel size
renderer.draw_texture(texture, x, y, w: 128, h: 128) # scaled
renderer.draw_texture(texture, x, y, src: [0, 0, 32, 32]) # crop to a source rect (e.g. one sprite-sheet frame)
renderer.draw_texture(texture, x, y, angle: 45, flip: :horizontal) # rotate/flip about the dst rect's center
renderer.draw_texture(texture, x, y, angle: 45, center: [0, 0])    # ...or an explicit pivot point

renderer.fill_polygon_textured(points, uvs, texture) # texture-mapped convex polygon/quad (points/uvs are
                                                       # flat [x0,y0,x1,y1,...]/[u0,v0,u1,v1,...] arrays)

texture.width
texture.height
texture.set_color_mod(255, 128, 64)  # tint this texture's pixels (0..255 each)
texture.set_alpha_mod(200)           # scale this texture's alpha (0..255)
texture.close
```

Same `__dir__` caveat as `SDL::Font.new` applies to `Texture.load`'s path — see "Fonts and portability" above.

### `SDL::Gamepad`

Poll/query-based — SDL3's gamepad API needs no callbacks. `SDL_INIT_GAMEPAD` is included in `Screen.open`'s default init flags.

```ruby
SDL::Gamepad.count           # number of connected gamepads
pad = SDL::Gamepad.open(0)   # by enumeration index, not instance ID — nil if none

pad.connected?
pad.name
pad.button(LibSDL::GAMEPAD_BUTTON_SOUTH)   # true/false
pad.axis(LibSDL::GAMEPAD_AXIS_LEFTX)       # -32768..32767
pad.rumble(low: 20000, high: 20000, duration_ms: 150)
pad.close
```

Handle `LibSDL::EVENT_GAMEPAD_ADDED` / `EVENT_GAMEPAD_REMOVED` from `SDL::Event.poll` to react to hotplug; `EVENT_GAMEPAD_BUTTON_DOWN` / `_UP` / `EVENT_GAMEPAD_AXIS_MOTION` carry `SDL::Event.gamepad_which` / `gamepad_button` / `gamepad_button_down?` / `gamepad_axis` / `gamepad_axis_value`.

### `SDL::Audio` and `SDL::Sound`

```ruby
# Procedural tone, no asset file — a lazily-opened, process-lifetime stream.
SDL::Audio.beep(freq: 440, duration_ms: 200, volume: 80)
SDL::Audio.queued_ms   # how much queued beep audio is still waiting to play

# A loaded WAV file, played on its own dedicated stream opened at the WAV's
# own native sample rate/channels/format (so playback is never a manual
# format-matching exercise).
sound = SDL::Sound.new("/absolute/path/to/sound.wav")
sound.play    # restarts from the beginning
sound.len     # PCM byte count
sound.close
```

`SDL_INIT_AUDIO` is included in `Screen.open`'s default init flags; no separate setup call is needed before either of these.

### `SDL::Synth`

A small multi-channel chip synth — independently-pitched software oscillators (waveform + ADSR envelope), mixed in C and pushed to one shared playback stream every frame. `SDL::Audio.beep`/`SDL::Sound` cover a one-shot tone or a pre-recorded file; `SDL::Synth` is for driving several simultaneous, independently-controllable voices in real time (a tracker/sequencer, a synth-driven soundtrack). Waveform math (8 shapes below, plus two filter bits) is a direct port of `pico8tools/lemmings/build_music.rb`'s `waveform_sample` (itself a port of zepto8's `synth.cpp`), not a from-scratch design.

```ruby
# waveform is one of: TRIANGLE, TILTED_SAW, SAW, SQUARE, PULSE, ORGAN, NOISE, PHASER
SDL::Synth.note_on(channel, freq_hz, SDL::Synth::SQUARE, volume) # volume 0.0..1.0
SDL::Synth.set_flags(channel, buzz, noiz)                        # PICO-8's waveform-reshaping bits
SDL::Synth.set_envelope(channel, attack_ms, decay_ms, sustain_level, release_ms)
SDL::Synth.note_off(channel)   # starts the release stage, doesn't hard-cut
SDL::Synth.pump(ms)            # call once per frame — synthesizes+queues real audio
SDL::Synth.queued_ms           # how much queued synth audio is still waiting to play
```

`channel` is `0...SDL::Synth::CHANNELS` (4 by default). `pump` is safe to call unconditionally every frame, even before any note has played — it's a no-op until the first `note_on` opens the stream. Note-level effects (slide, vibrato, arpeggio, fades) aren't a C-side feature: resolve them in the caller by recomputing `freq_hz`/`volume` per tick and re-issuing `note_on`, the same way a tracker's playback routine already works.

### Multi-window

`SDL::Screen.open` only ever opens one `Window`/`Renderer` pair, but neither class was ever a singleton — a second independent pair is just a second `Window.new` / `Renderer.new`:

```ruby
SDL::Screen.open("Window A", width: 480, height: 320) do |window_a, renderer_a|
  window_b   = SDL::Window.new("Window B", width: 480, height: 320)
  renderer_b = SDL::Renderer.new(window_b)

  # ... main loop: dispatch each polled event by SDL::Event.window_id,
  # matched against window_a.id / window_b.id (SDL_GetWindowID) ...

  renderer_b.close
  window_b.close
end
```

See `bin/multi_window_demo.rb` for the full dispatch loop.

### Touch and pen

Both flow through `SDL::Event.poll` like keyboard/mouse — no extra setup.

```ruby
when LibSDL::EVENT_FINGER_DOWN, LibSDL::EVENT_FINGER_MOTION, LibSDL::EVENT_FINGER_UP
  SDL::Event.touch_x         # normalized 0..1
  SDL::Event.touch_y         # normalized 0..1
  SDL::Event.touch_dx        # normalized -1..1, motion since last event
  SDL::Event.touch_dy
  SDL::Event.touch_pressure  # normalized 0..1

when LibSDL::EVENT_PEN_DOWN, LibSDL::EVENT_PEN_MOTION, LibSDL::EVENT_PEN_UP,
     LibSDL::EVENT_PEN_BUTTON_DOWN, LibSDL::EVENT_PEN_BUTTON_UP, LibSDL::EVENT_PEN_AXIS
  SDL::Event.pen_x            # window-relative pixels
  SDL::Event.pen_y
  SDL::Event.pen_down?
  SDL::Event.pen_eraser?      # true if using the eraser end
  SDL::Event.pen_button       # button index (EVENT_PEN_BUTTON_* only)
  SDL::Event.pen_button_down?
  SDL::Event.pen_axis         # LibSDL::PEN_AXIS_* (EVENT_PEN_AXIS only)
  SDL::Event.pen_axis_value
```

### `SDL::Log`

Optional file logger. Useful when you can't write to stdout during an SDL session.

```ruby
SDL::Log.open("/tmp/sdl.log")   # call before Screen.open
SDL::Log.write("message")
# SDL::Log.close is called automatically by Screen.open's ensure clause
```

## Constants

### Event types (`LibSDL::*`)

| Constant | Value |
|----------|-------|
| `QUIT` | `0x100` |
| `KEYDOWN` | `0x300` |
| `KEYUP` | `0x301` |
| `MOUSEMOTION` | `0x400` |
| `MOUSEBUTTONDOWN` | `0x401` |
| `MOUSEBUTTONUP` | `0x402` |
| `MOUSEWHEEL` | `0x403` |
| `EVENT_WINDOW_PIXEL_SIZE_CHANGED` | `0x207` |

### Key codes (`LibSDL::K_*`)

Printable characters map 1:1 to ASCII. Special keys:

| Constant | Description |
|----------|-------------|
| `K_UP K_DOWN K_LEFT K_RIGHT` | Arrow keys |
| `K_RETURN` | Enter |
| `K_ESCAPE` | Escape |
| `K_BACKSPACE` | Backspace |
| `K_TAB` | Tab |
| `K_SPACE` | Space |
| `K_F1` – `K_F12` | Function keys |

### Modifier flags (`LibSDL::KMOD_*`)

`KMOD_SHIFT`, `KMOD_CTRL`, `KMOD_ALT` (also `KMOD_LSHIFT`, `KMOD_RSHIFT`, etc.)

### Mouse buttons (`LibSDL::BUTTON_*`)

`BUTTON_LEFT`, `BUTTON_MIDDLE`, `BUTTON_RIGHT`

### Gamepad buttons/axes (`LibSDL::GAMEPAD_BUTTON_*` / `GAMEPAD_AXIS_*`)

`GAMEPAD_BUTTON_SOUTH EAST WEST NORTH BACK GUIDE START LEFT_STICK RIGHT_STICK LEFT_SHOULDER RIGHT_SHOULDER DPAD_UP DPAD_DOWN DPAD_LEFT DPAD_RIGHT`

`GAMEPAD_AXIS_LEFTX LEFTY RIGHTX RIGHTY LEFT_TRIGGER RIGHT_TRIGGER`

### Pen axes (`LibSDL::PEN_AXIS_*`)

`PEN_AXIS_PRESSURE XTILT YTILT DISTANCE ROTATION SLIDER TANGENTIAL_PRESSURE`

### More event types (`LibSDL::*`)

`EVENT_GAMEPAD_ADDED REMOVED BUTTON_DOWN BUTTON_UP AXIS_MOTION`, `EVENT_FINGER_DOWN UP MOTION CANCELED`, `EVENT_PEN_DOWN UP BUTTON_DOWN BUTTON_UP MOTION AXIS`

## C shim

SDL3's `SDL_Event` is a C union and `SDL_FRect` is a struct — neither can be constructed directly through Spinel's FFI DSL. `sdl/shim.c` is compiled into the binary alongside the generated code and provides plain-function accessors for event fields and rect-based draw calls. The approach is identical to the `mouse_shim.c` in the spinel-ncurses library.

`shim.c` also embeds sdl's bundled fonts (`sdl/fonts/*.ttf`) as compiled-in byte arrays, generated at build time by `bin2c.c` and linked in by `build_shim.sh`. `sdl_open_bundled_font` wraps them with `SDL_IOFromConstMem` + `TTF_OpenFontIO` so `SDL::Font.bundled` never touches the filesystem at runtime — see "Fonts and portability" above for why that matters.

`shim.c` also carries: `sdl_event_window_id` (dispatches on event category — SDL3 has no one shared union member for it), the gamepad/touch/pen event-field accessors, `sdl_audio_beep` (synthesizes a sine wave directly in C — Spinel's FFI has no bulk-array spec shaped for raw PCM bytes) and the `sdl_wav_*` family (loads a WAV onto its own dedicated audio stream, opened at the WAV's native format), the `sdl_synth_*` family (a small fixed bank of oscillator+envelope channels, mixed in C for the same bulk-PCM-through-FFI reason as `sdl_audio_beep` — see `SDL::Synth` above), and `sdl_surface_width`/`height`. A handful of `sdl_test_push_*_event` functions at the bottom inject synthetic events via `SDL_PushEvent` purely so `test/*.rb` can exercise the touch/pen/gamepad accessors deterministically without real hardware attached, plus `sdl_synth_test_active` (exposes a channel's envelope-active flag so `test/synth.rb` can confirm release actually reaches silence) — none of this test-support group is part of the public API.

## Examples

| Program | Description |
|---------|-------------|
| `bin/demo.rb` | Bouncing colored rectangle |
| `bin/snake.rb` | Classic Snake — arrow keys to steer, R to restart, Esc to quit |
| `bin/mouse_demo.rb` | Mouse position/buttons/clicks |
| `bin/gamepad_demo.rb` | Live button/axis display + rumble on button press; handles hotplug |
| `bin/image_demo.rb` | `SDL_image` texture loading — native/scaled/orbiting/tiled draws |
| `bin/audio_demo.rb` | Procedural beep tones (1-5 keys) + loaded-WAV playback (space) |
| `bin/synth_demo.rb` | Multi-channel chip synth — waveform switching (1-8), a 4-channel arpeggio (space), live envelope tweaking (up/down) |
| `bin/multi_window_demo.rb` | Two independent windows, events routed by `SDL::Event.window_id` |
| `bin/touch_pen_demo.rb` | Touch/pen event visualization, with a mouse fallback shape |

Build all examples:

```sh
spin build
```

Run an example:

```sh
spin run demo
```

Or after building:

```sh
./build/bin/demo
```

## Tests

```sh
spin test
```

Snapshot tests print to stdout and diff against `.expected` files in `test/`. `test/gamepad_events.rb`, `test/touch_events.rb`, and `test/pen_events.rb` inject synthetic events via the `sdl_test_push_*_event` shim helpers (see "C shim" above) so they're deterministic without real hardware; `test/audio.rb`, `test/synth.rb`, and `test/image.rb` exercise `SDL::Audio`/`SDL::Sound`/`SDL::Synth`/`SDL::Texture` against the fixtures in `sdl/assets/` (`test.wav`, `test.bmp` — both hand-built with no external tooling, see the generator scripts referenced in their header comments); `test/multi_window.rb` covers opening a second independent `Window`/`Renderer` pair.

## License

MIT — see [LICENSE](LICENSE).
