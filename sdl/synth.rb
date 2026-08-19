module SDL
  # A small multi-channel chip synth: independently-pitched software
  # oscillators (waveform + ADSR envelope), mixed and pushed to one shared
  # playback stream every SDL::Synth.pump(ms) call — see sdl_synth_pump in
  # shim.c for why synthesis/mixing has to happen in C (the same
  # bulk-PCM-through-FFI gap SDL::Audio.beep already works around).
  #
  # Waveform math (all 8 shapes below, plus the buzz/noiz filter bits) is a
  # direct port of pico8tools/lemmings/build_music.rb's `waveform_sample`,
  # itself a port of zepto8's synth.cpp, cross-checked there against real
  # PICO-8 WAV exports — not a from-scratch design.
  module Synth
    TRIANGLE   = 0
    TILTED_SAW = 1
    SAW        = 2
    SQUARE     = 3
    PULSE      = 4
    ORGAN      = 5
    NOISE      = 6
    PHASER     = 7

    CHANNELS = 4 # channel ids 0..3 — see SDL_SYNTH_CHANNELS in shim.c

    # Starts (or retriggers) channel `ch` at freq_hz playing `waveform`, at
    # `volume` (0.0..1.0), running its envelope from the attack stage (or
    # straight to sustain if attack_ms is 0, the default — see
    # set_envelope). freq_hz takes a Float; a standard MIDI note number
    # converts via `440.0 * 2 ** ((midi - 69) / 12.0)`.
    def self.note_on(ch, freq_hz, waveform, volume)
      LibSDL.sdl_synth_note_on(ch, freq_hz.to_f, waveform, volume.to_f)
    end

    # buzz/noiz: PICO-8's two waveform-reshaping filter bits (bool).
    # Persists across note_on calls on the same channel until changed again.
    def self.set_flags(ch, buzz, noiz)
      LibSDL.sdl_synth_set_flags(ch, buzz ? 1 : 0, noiz ? 1 : 0)
    end

    # ADSR envelope for channel `ch`: attack/decay/release in ms,
    # sustain_level 0.0..1.0 (fraction of note_on's volume held during the
    # sustain stage). Persists across note_on calls on the same channel
    # until changed again — set once per instrument, not per note. The
    # default (all zero attack/decay/release, sustain_level 1.0) is an
    # instant on/off, matching SDL::Audio.beep's own no-envelope behavior.
    def self.set_envelope(ch, attack_ms, decay_ms, sustain_level, release_ms)
      LibSDL.sdl_synth_set_envelope(ch, attack_ms.to_f, decay_ms.to_f, sustain_level.to_f, release_ms.to_f)
    end

    # Starts channel `ch`'s release stage — does not hard-cut; it fades out
    # over its envelope's release_ms (immediately, if release_ms is 0).
    def self.note_off(ch)
      LibSDL.sdl_synth_note_off(ch)
    end

    # Synthesizes+mixes `ms` worth of audio for every active channel and
    # queues it. Call this once per frame from the main loop (same cadence
    # as renderer.present/Screen.delay) — safe to call unconditionally even
    # before any note has ever played (a no-op until the first note_on
    # opens the stream). See shim.c for why a single frame-quantized push,
    # not a sample-accurate callback, is the right model for a
    # tracker-driven sequencer.
    def self.pump(ms)
      LibSDL.sdl_synth_pump(ms)
    end

    # Milliseconds of already-queued synth audio still waiting to play.
    def self.queued_ms
      LibSDL.sdl_synth_queued_ms
    end
  end
end
