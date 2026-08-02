require "sdl"

SDL::Log.open("/tmp/sdl_audio_demo.log")

# Number keys 1-5 beep a different pitch (procedural, SDL::Audio.beep — no
# asset file). Space plays sdl/assets/test.wav (SDL::Sound — a loaded PCM
# file), which can overlap with a beep since each Sound gets its own
# dedicated audio stream (see shim.c's sdl_load_wav).
WAV_PATH = File.join(__dir__, "..", "sdl", "assets", "test.wav")

NOTE_KEYS = {
  49 => 261, # "1" -> C4
  50 => 293, # "2" -> D4
  51 => 329, # "3" -> E4
  52 => 349, # "4" -> F4
  53 => 392, # "5" -> G4
}

SDL::Screen.open("Audio Demo", width: 640, height: 300) do |window, renderer|
  window.title = "Audio Demo (#{window.width}x#{window.height})"
  font = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 24)
  sound = SDL::Sound.new(WAV_PATH)
  last_msg = "Press 1-5 for a beep, SPACE to play test.wav, ESC to quit"

  running = true
  while running
    while (event_type = SDL::Event.poll)
      if event_type == LibSDL::QUIT
        running = false
      elsif event_type == LibSDL::KEYDOWN
        key = SDL::Event.key_sym
        if key == LibSDL::K_ESCAPE
          running = false
        elsif key == LibSDL::K_SPACE
          sound.play
          last_msg = "Playing test.wav (#{sound.len} bytes)"
        elsif NOTE_KEYS.key?(key)
          freq = NOTE_KEYS[key]
          SDL::Audio.beep(freq: freq, duration_ms: 300, volume: 60)
          last_msg = "Beep at #{freq} Hz"
        end
      end
    end

    renderer.draw_color(10, 10, 20)
    renderer.clear

    hud = SDL::Color::WHITE
    renderer.draw_text(font, last_msg, 8, 8, hud[0], hud[1], hud[2], hud[3])
    renderer.draw_text(font, "Queued: #{SDL::Audio.queued_ms}ms", 8, 40, hud[0], hud[1], hud[2], hud[3])

    # A bar showing how much beep audio is still queued, so the effect of
    # queued_ms draining over real time is visible without needing sound
    # hardware to actually verify anything.
    queued = SDL::Audio.queued_ms
    renderer.draw_color(0, 200, 255)
    renderer.fill_rect(8, 70, [queued, 600].min, 20)

    renderer.present
    SDL::Screen.delay(16)
  end

  sound.close
  font.close
end
