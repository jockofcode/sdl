require "sdl"

# Exercises SDL::Synth's control API end-to-end: note_on opens the shared
# stream and starts producing audio, pump() synthesizes+queues real
# samples, note_off starts the release stage, and sdl_synth_test_active
# (test-support only, see shim.c) confirms the ADSR state machine actually
# reaches IDLE once release_ms has elapsed. volume: 0 keeps playback silent
# while still exercising the full synthesize-and-queue code path, same
# convention as test/audio.rb's beep test.
SDL::Screen.open("Synth Test", width: 320, height: 240) do |window, renderer|
  window.title = "Synth Test"
  renderer.draw_color(0, 0, 0)
  renderer.clear

  puts SDL::Synth.queued_ms == 0

  ok = SDL::Synth.note_on(0, 440.0, SDL::Synth::SQUARE, 0.0)
  puts ok != 0
  puts LibSDL.sdl_synth_test_active(0) != 0

  pumped = SDL::Synth.pump(50)
  puts pumped != 0
  puts SDL::Synth.queued_ms > 0

  off_ok = SDL::Synth.note_off(0)
  puts off_ok != 0
  # A channel already releasing (or idle) rejects a second note_off.
  puts SDL::Synth.note_off(0) == 0

  # A 20ms release envelope, set before this note_on, must have fully
  # faded to IDLE well within 200ms of pump time.
  SDL::Synth.set_envelope(1, 0.0, 0.0, 1.0, 20.0)
  SDL::Synth.note_on(1, 220.0, SDL::Synth::TRIANGLE, 0.0)
  puts LibSDL.sdl_synth_test_active(1) != 0
  SDL::Synth.note_off(1)
  SDL::Synth.pump(200)
  puts LibSDL.sdl_synth_test_active(1) == 0

  # All 8 waveforms + both filter bits run without error across every
  # channel, each producing real queued audio.
  before = SDL::Synth.queued_ms
  8.times do |wf|
    ch = wf % SDL::Synth::CHANNELS
    SDL::Synth.set_flags(ch, wf.even?, wf.odd?)
    SDL::Synth.note_on(ch, 110.0 * (wf + 1), wf, 0.0)
  end
  SDL::Synth.pump(20)
  puts SDL::Synth.queued_ms > before

  # set_freq/set_volume update a live channel without resetting its
  # active/envelope state (unlike note_on) -- confirmed by test_active
  # staying true across both calls, not just the calls themselves
  # succeeding.
  SDL::Synth.note_on(2, 440.0, SDL::Synth::SAW, 0.0)
  puts SDL::Synth.set_freq(2, 880.0) != 0
  puts LibSDL.sdl_synth_test_active(2) != 0
  puts SDL::Synth.set_volume(2, 0.3) != 0
  puts LibSDL.sdl_synth_test_active(2) != 0

  # Both are no-ops (return 0) on a channel that's gone IDLE.
  SDL::Synth.note_off(2)
  SDL::Synth.pump(200)
  puts LibSDL.sdl_synth_test_active(2) == 0
  puts SDL::Synth.set_freq(2, 220.0) == 0
  puts SDL::Synth.set_volume(2, 0.5) == 0
end
