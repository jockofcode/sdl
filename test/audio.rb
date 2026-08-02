require "sdl"

# Exercises both audio paths: SDL::Audio.beep (procedural, no asset file)
# and SDL::Sound (loads test.wav, a hand-built 16-bit mono PCM fixture — see
# sdl/assets/test.wav / the scratchpad make_wav.py that generated it).
# volume: 0 keeps the beep silent while still exercising the full
# synthesize-and-queue code path (SDL_OpenAudioDeviceStream,
# SDL_PutAudioStreamData, SDL_GetAudioStreamQueued all actually run).
SDL::Screen.open("Audio Test", width: 320, height: 240) do |window, renderer|
  window.title = "Audio Test"
  renderer.draw_color(0, 0, 0)
  renderer.clear
  puts SDL::Audio.queued_ms == 0

  ok = SDL::Audio.beep(freq: 440, duration_ms: 100, volume: 0)
  puts ok != 0
  puts SDL::Audio.queued_ms > 0

  sound = SDL::Sound.new(File.join(__dir__, "..", "sdl", "assets", "test.wav"))
  puts sound.len == 1600 # 800 samples * 2 bytes (16-bit mono, see make_wav.py)

  play_ok = sound.play
  puts play_ok != 0

  sound.close
end
