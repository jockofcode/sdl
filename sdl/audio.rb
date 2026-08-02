module SDL
  # Procedural tones — no asset file needed. Backed by one lazily-opened,
  # process-lifetime playback stream (see sdl_audio_beep in shim.c); each
  # call synthesizes duration_ms of a sine wave at freq Hz and queues it.
  module Audio
    # freq: Hz. duration_ms: length of the tone. volume: 0..100.
    def self.beep(freq: 440, duration_ms: 200, volume: 80)
      LibSDL.sdl_audio_beep(freq, duration_ms, volume)
    end

    # Milliseconds of already-queued beep audio still waiting to play.
    def self.queued_ms
      LibSDL.sdl_audio_queued_ms
    end
  end

  # A WAV file loaded once and played (possibly many times) on its own
  # dedicated audio stream, opened at the WAV's own native sample rate/
  # channels/format — see sdl_load_wav in shim.c for why that avoids a
  # format-mismatch footgun.
  class Sound
    attr_reader :ptr

    def initialize(path)
      @ptr = LibSDL.sdl_load_wav(path)
      Log.write("sdl_load_wav(#{path}): #{@ptr == nil ? "NULL — #{LibSDL.SDL_GetError}" : "ok"}")
    end

    # Restarts playback from the beginning.
    def play
      LibSDL.sdl_wav_play(@ptr)
    end

    # Size in bytes of the loaded PCM buffer (0 if loading failed).
    def len
      LibSDL.sdl_wav_len(@ptr)
    end

    def close
      LibSDL.sdl_wav_free(@ptr)
      Log.write("sdl_wav_free: done")
    end
  end
end
