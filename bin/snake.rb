require "sdl"

SDL::Log.open("/tmp/sdl_snake.log")

CELL = 20
COLS = 40
ROWS = 30
WIDTH  = CELL * COLS
HEIGHT = CELL * ROWS

MOVE_INTERVAL = 100 # ms between grid steps
R_KEY = "r".ord

def random_cell
  [rand(COLS), rand(ROWS)]
end

def spawn_food(snake)
  cell = random_cell
  while snake.include?(cell)
    cell = random_cell
  end
  cell
end

def reset_state
  cx = COLS / 2
  cy = ROWS / 2
  snake = [[cx, cy], [cx - 1, cy], [cx - 2, cy]]

  {
    snake:     snake,
    dir:       [1, 0],
    next_dir:  [1, 0],
    food:      spawn_food(snake),
    score:     0,
    game_over: false,
  }
end

SDL::Screen.open("Snake", width: WIDTH, height: HEIGHT, flags: 0) do |window, renderer|
  font      = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 28)
  state     = reset_state
  last_move = SDL::Screen.ticks
  running   = true

  while running
    while (event_type = SDL::Event.poll)
      if event_type == LibSDL::QUIT
        running = false
      elsif event_type == LibSDL::KEYDOWN
        key = SDL::Event.key_sym

        if key == LibSDL::K_ESCAPE
          running = false
        elsif state[:game_over]
          if key == R_KEY
            state     = reset_state
            last_move = SDL::Screen.ticks
            window.title = "Snake"
          end
        elsif key == LibSDL::K_UP && state[:dir] != [0, 1]
          state[:next_dir] = [0, -1]
        elsif key == LibSDL::K_DOWN && state[:dir] != [0, -1]
          state[:next_dir] = [0, 1]
        elsif key == LibSDL::K_LEFT && state[:dir] != [1, 0]
          state[:next_dir] = [-1, 0]
        elsif key == LibSDL::K_RIGHT && state[:dir] != [-1, 0]
          state[:next_dir] = [1, 0]
        end
      end
    end

    if !state[:game_over] && SDL::Screen.ticks - last_move >= MOVE_INTERVAL
      last_move += MOVE_INTERVAL
      state[:dir] = state[:next_dir]

      snake = state[:snake]
      dir   = state[:dir]
      head  = snake[0]
      new_head = [head[0] + dir[0], head[1] + dir[1]]

      hit_wall = new_head[0] < 0 || new_head[0] >= COLS || new_head[1] < 0 || new_head[1] >= ROWS
      hit_self = snake.include?(new_head)

      if hit_wall || hit_self
        state[:game_over] = true
        window.title = "Snake — Game Over (score #{state[:score]}) — R to restart, Esc to quit"
      else
        snake.insert(0, new_head)

        if new_head == state[:food]
          state[:score] += 1
          state[:food]   = spawn_food(snake)
          window.title   = "Snake — score #{state[:score]}"
        else
          snake.pop
        end
      end
    end

    bg = SDL::Color::BLACK
    renderer.draw_color(bg[0], bg[1], bg[2], bg[3])
    renderer.clear

    food = state[:food]
    fc = SDL::Color::RED
    renderer.draw_color(fc[0], fc[1], fc[2], fc[3])
    renderer.fill_rect(food[0] * CELL, food[1] * CELL, CELL, CELL)

    state[:snake].each_with_index do |seg, i|
      color = i == 0 ? SDL::Color::YELLOW : SDL::Color::GREEN
      renderer.draw_color(color[0], color[1], color[2], color[3])
      renderer.fill_rect(seg[0] * CELL, seg[1] * CELL, CELL - 1, CELL - 1)
    end

    border = SDL::Color::GRAY
    renderer.draw_color(border[0], border[1], border[2], border[3])
    renderer.draw_rect(0, 0, WIDTH - 1, HEIGHT - 1)

    hud = SDL::Color::WHITE
    label = state[:game_over] ? "Game Over — score #{state[:score]} — R to restart" : "Score #{state[:score]}"
    renderer.draw_text(font, label, 8, 4, hud[0], hud[1], hud[2], hud[3])

    renderer.present
    SDL::Screen.delay(16)
  end

  font.close
end
