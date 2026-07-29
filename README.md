# sdl

SDL2 graphics bindings for [Spinel](https://github.com/matz/spinel), an ahead-of-time Ruby compiler.

Uses Spinel's built-in FFI DSL (`ffi_lib`, `ffi_func`, `ffi_const`) — no external gems required.

## Requirements

- Spinel (`spin`)
- SDL2 (`brew install sdl2` on macOS)

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

The `flags:` keyword accepts any combination of `LibSDL::WINDOW_*` constants and defaults to `WINDOW_SHOWN | WINDOW_RESIZABLE`.

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
  when LibSDL::WINDOWEVENT
    SDL::Event.window_event_id   # LibSDL::WINDOWEVENT_* sub-type
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
| `WINDOWEVENT` | `0x200` |
| `KEYDOWN` | `0x300` |
| `KEYUP` | `0x301` |
| `MOUSEMOTION` | `0x400` |
| `MOUSEBUTTONDOWN` | `0x401` |
| `MOUSEBUTTONUP` | `0x402` |
| `MOUSEWHEEL` | `0x403` |

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

### Window event sub-types (`LibSDL::WINDOWEVENT_*`)

`WINDOWEVENT_RESIZED`, `WINDOWEVENT_SIZE_CHANGED`, `WINDOWEVENT_CLOSE`

## C shim

SDL2's `SDL_Event` is a C union and `SDL_Rect` is a struct — neither can be constructed directly through Spinel's FFI DSL. `sdl/shim.c` is compiled into the binary alongside the generated code and provides plain-function accessors for event fields and rect-based draw calls. The approach is identical to the `mouse_shim.c` in the spinel-ncurses library.

## Examples

| Program | Description |
|---------|-------------|
| `bin/demo.rb` | Bouncing colored rectangle |

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

Snapshot tests print to stdout and diff against `.expected` files in `test/`.

## License

MIT — see [LICENSE](LICENSE).
