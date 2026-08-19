require "sdl"

SDL::Log.open("/tmp/sdl_synth_demo.log")

# Keys 1-8 retrigger channel 0 with a different waveform at the same pitch,
# so the timbre difference is audible back-to-back; Space triggers a
# 4-channel arpeggio (one waveform per channel) to show simultaneous
# independently-pitched voices actually mixing, not playing sequentially
# like SDL::Audio.beep's shared mono stream does. Up/Down adjust channel
# 0's release time to hear the envelope's fade-out change.
WAVEFORM_KEYS = {
  49 => [SDL::Synth::TRIANGLE,   "triangle"],
  50 => [SDL::Synth::TILTED_SAW, "tilted saw"],
  51 => [SDL::Synth::SAW,        "saw"],
  52 => [SDL::Synth::SQUARE,     "square"],
  53 => [SDL::Synth::PULSE,      "pulse"],
  54 => [SDL::Synth::ORGAN,      "organ"],
  55 => [SDL::Synth::NOISE,      "noise"],
  56 => [SDL::Synth::PHASER,     "phaser"],
}

ARPEGGIO = [
  [261.63, SDL::Synth::SQUARE],   # C4
  [329.63, SDL::Synth::PULSE],    # E4
  [392.00, SDL::Synth::TRIANGLE], # G4
  [523.25, SDL::Synth::ORGAN],    # C5
]

SDL::Screen.open("Synth Demo", width: 640, height: 300) do |window, renderer|
  window.title = "Synth Demo (#{window.width}x#{window.height})"
  font = SDL::Font.bundled(SDL::Fonts::VT323_NAME, 24)
  release_ms = 300.0
  SDL::Synth.set_envelope(0, 5.0, 50.0, 0.6, release_ms)
  last_msg = "1-8: waveform on ch0, SPACE: 4-channel arpeggio, UP/DOWN: release time, ESC: quit"

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
          ARPEGGIO.each_with_index do |(freq, wf), ch|
            SDL::Synth.note_on(ch, freq, wf, 70.0 / 100.0)
          end
          last_msg = "Arpeggio: 4 channels, 4 waveforms, at once"
        elsif key == LibSDL::K_UP
          release_ms = [release_ms + 50.0, 2000.0].min
          SDL::Synth.set_envelope(0, 5.0, 50.0, 0.6, release_ms)
          last_msg = "Channel 0 release: #{release_ms.to_i}ms"
        elsif key == LibSDL::K_DOWN
          release_ms = [release_ms - 50.0, 0.0].max
          SDL::Synth.set_envelope(0, 5.0, 50.0, 0.6, release_ms)
          last_msg = "Channel 0 release: #{release_ms.to_i}ms"
        elsif WAVEFORM_KEYS.key?(key)
          waveform, name = WAVEFORM_KEYS[key]
          SDL::Synth.note_on(0, 220.0, waveform, 70.0 / 100.0)
          SDL::Synth.note_off(0)
          last_msg = "Channel 0: #{name}"
        end
      end
    end

    # Feed the synth every frame, same cadence as renderer.present/
    # Screen.delay — see SDL::Synth.pump's doc comment.
    SDL::Synth.pump(16)

    renderer.draw_color(10, 10, 20)
    renderer.clear

    hud = SDL::Color::WHITE
    renderer.draw_text(font, last_msg, 8, 8, hud[0], hud[1], hud[2], hud[3])
    renderer.draw_text(font, "Queued: #{SDL::Synth.queued_ms}ms", 8, 40, hud[0], hud[1], hud[2], hud[3])

    queued = SDL::Synth.queued_ms
    renderer.draw_color(0, 200, 255)
    renderer.fill_rect(8, 70, [queued, 600].min, 20)

    renderer.present
    SDL::Screen.delay(16)
  end

  font.close
end
