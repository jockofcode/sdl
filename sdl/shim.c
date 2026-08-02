#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <SDL3_image/SDL_image.h>
#include <stdint.h>
#include <string.h>

/* Static event buffer — populated by sdl_poll_event(), read by the field accessors. */
static SDL_Event sdl_event;

intptr_t sdl_poll_event(void) {
    return (intptr_t)SDL_PollEvent(&sdl_event);
}

intptr_t sdl_event_type(void) {
    return (intptr_t)sdl_event.type;
}

/* Key event fields — SDL3 flattened the old .key.keysym.{sym,mod} indirection to .key.{key,mod}. */
intptr_t sdl_key_sym(void) { return (intptr_t)sdl_event.key.key; }
intptr_t sdl_key_mod(void) { return (intptr_t)sdl_event.key.mod; }

/* Mouse motion / button fields — check event type to pick the right union
   member. Coordinates are float in SDL3; truncate to int for this
   binding's pixel-integer call sites. */
intptr_t sdl_mouse_x(void) {
    if (sdl_event.type == SDL_EVENT_MOUSE_MOTION)
        return (intptr_t)sdl_event.motion.x;
    return (intptr_t)sdl_event.button.x;
}

intptr_t sdl_mouse_y(void) {
    if (sdl_event.type == SDL_EVENT_MOUSE_MOTION)
        return (intptr_t)sdl_event.motion.y;
    return (intptr_t)sdl_event.button.y;
}

intptr_t sdl_mouse_button(void)  { return (intptr_t)sdl_event.button.button; }
intptr_t sdl_mouse_clicks(void)  { return (intptr_t)sdl_event.button.clicks; }

/* Mouse wheel fields — use SDL3's integer_x/integer_y (whole scroll
   "ticks"), the closest match to SDL2's originally-integer wheel.x/y,
   rather than the new fractional x/y floats. */
intptr_t sdl_wheel_x(void) { return (intptr_t)sdl_event.wheel.integer_x; }
intptr_t sdl_wheel_y(void) { return (intptr_t)sdl_event.wheel.integer_y; }

/* SDL_FRect wrappers — SDL_RenderFillRect / SDL_RenderRect (renamed from
   SDL_RenderDrawRect) take a float-rect struct pointer that can't be
   constructed directly from Ruby, so we build it here. */
intptr_t sdl_render_fill_rect(SDL_Renderer *r, int x, int y, int w, int h) {
    SDL_FRect rect = {(float)x, (float)y, (float)w, (float)h};
    return (intptr_t)SDL_RenderFillRect(r, &rect);
}

intptr_t sdl_render_draw_rect(SDL_Renderer *r, int x, int y, int w, int h) {
    SDL_FRect rect = {(float)x, (float)y, (float)w, (float)h};
    return (intptr_t)SDL_RenderRect(r, &rect);
}

/* SDL_GetWindowSize takes int* out-parameters — expose each axis separately. */
intptr_t sdl_get_window_width(SDL_Window *w) {
    int width, height;
    SDL_GetWindowSize(w, &width, &height);
    return (intptr_t)width;
}

intptr_t sdl_get_window_height(SDL_Window *w) {
    int width, height;
    SDL_GetWindowSize(w, &width, &height);
    return (intptr_t)height;
}

/* TTF_RenderText_Blended's SDL_Color arg is passed by value, which the FFI
   DSL can't express — take components as ints and build the struct here.
   length=0 tells SDL_ttf to treat text as NUL-terminated. */
intptr_t sdl_ttf_render_text_blended(TTF_Font *font, const char *text, int r, int g, int b, int a) {
    SDL_Color fg = {(Uint8)r, (Uint8)g, (Uint8)b, (Uint8)a};
    return (intptr_t)TTF_RenderText_Blended(font, text, 0, fg);
}

/* SDL_GetTextureSize takes float* out-parameters, same story as the window
   size helpers above. */
intptr_t sdl_get_texture_width(SDL_Texture *t) {
    float w, h;
    SDL_GetTextureSize(t, &w, &h);
    return (intptr_t)w;
}

intptr_t sdl_get_texture_height(SDL_Texture *t) {
    float w, h;
    SDL_GetTextureSize(t, &w, &h);
    return (intptr_t)h;
}

/* SDL_RenderTexture's dst is an SDL_FRect pointer — same construction-site
   problem as the rect helpers above. Passing NULL as srcrect renders the
   whole texture. */
intptr_t sdl_render_texture(SDL_Renderer *r, SDL_Texture *t, int x, int y, int w, int h) {
    SDL_FRect dst = {(float)x, (float)y, (float)w, (float)h};
    return (intptr_t)SDL_RenderTexture(r, t, NULL, &dst);
}

/* Bundled fonts, compiled in as byte arrays by build_shim.sh (see
   bin2c.c and fonts_embed.c). Spinel's __dir__ is a compile-time literal
   of the source tree that compiled the binary, not the running
   executable's location, so a path built from it (as TTF_OpenFont
   requires) only resolves on that same machine. Loading straight from
   memory via SDL_IOFromConstMem + TTF_OpenFontIO sidesteps that: no
   path, so a compiled binary carries its own fonts wherever it goes. */
extern const unsigned char sdl_font_bytes_vt323[];
extern const unsigned int  sdl_font_bytes_vt323_len;
extern const unsigned char sdl_font_bytes_public_sans[];
extern const unsigned int  sdl_font_bytes_public_sans_len;
extern const unsigned char sdl_font_bytes_jetbrains_mono[];
extern const unsigned int  sdl_font_bytes_jetbrains_mono_len;

intptr_t sdl_open_bundled_font(const char *name, float size) {
    const unsigned char *bytes = NULL;
    unsigned int len = 0;

    if (strcmp(name, "vt323") == 0) {
        bytes = sdl_font_bytes_vt323;
        len   = sdl_font_bytes_vt323_len;
    } else if (strcmp(name, "public_sans") == 0) {
        bytes = sdl_font_bytes_public_sans;
        len   = sdl_font_bytes_public_sans_len;
    } else if (strcmp(name, "jetbrains_mono") == 0) {
        bytes = sdl_font_bytes_jetbrains_mono;
        len   = sdl_font_bytes_jetbrains_mono_len;
    } else {
        return (intptr_t)NULL;
    }

    SDL_IOStream *io = SDL_IOFromConstMem(bytes, (size_t)len);
    if (!io) return (intptr_t)NULL;
    return (intptr_t)TTF_OpenFontIO(io, true, size);
}

/* Which window a polled event belongs to — SDL3 flattened window events to
   top-level types (see EVENT_WINDOW_PIXEL_SIZE_CHANGED's declaration in
   ffi.rb) but every event category still carries its own windowID field at
   its own struct offset, so this has to dispatch on the event's category
   rather than read one shared union member. */
intptr_t sdl_event_window_id(void) {
    Uint32 t = sdl_event.type;
    if (t >= SDL_EVENT_WINDOW_FIRST && t <= SDL_EVENT_WINDOW_LAST) return (intptr_t)sdl_event.window.windowID;
    if (t == SDL_EVENT_KEY_DOWN || t == SDL_EVENT_KEY_UP) return (intptr_t)sdl_event.key.windowID;
    if (t == SDL_EVENT_MOUSE_MOTION) return (intptr_t)sdl_event.motion.windowID;
    if (t == SDL_EVENT_MOUSE_BUTTON_DOWN || t == SDL_EVENT_MOUSE_BUTTON_UP) return (intptr_t)sdl_event.button.windowID;
    if (t == SDL_EVENT_MOUSE_WHEEL) return (intptr_t)sdl_event.wheel.windowID;
    if (t == SDL_EVENT_FINGER_DOWN || t == SDL_EVENT_FINGER_UP ||
        t == SDL_EVENT_FINGER_MOTION || t == SDL_EVENT_FINGER_CANCELED) return (intptr_t)sdl_event.tfinger.windowID;
    if (t == SDL_EVENT_PEN_MOTION) return (intptr_t)sdl_event.pmotion.windowID;
    if (t == SDL_EVENT_PEN_DOWN || t == SDL_EVENT_PEN_UP) return (intptr_t)sdl_event.ptouch.windowID;
    if (t == SDL_EVENT_PEN_BUTTON_DOWN || t == SDL_EVENT_PEN_BUTTON_UP) return (intptr_t)sdl_event.pbutton.windowID;
    if (t == SDL_EVENT_PEN_AXIS) return (intptr_t)sdl_event.paxis.windowID;
    return 0;
}

/* Gamepad event fields — SDL_GamepadDeviceEvent/ButtonEvent/AxisEvent all
   share an identical type+reserved+timestamp+which prefix (SDL_events.h),
   so reading .gdevice.which is safe regardless of which of the three the
   current polled event actually is. */
intptr_t sdl_gamepad_which(void)       { return (intptr_t)sdl_event.gdevice.which; }
intptr_t sdl_gamepad_button(void)      { return (intptr_t)sdl_event.gbutton.button; }
intptr_t sdl_gamepad_button_down(void) { return (intptr_t)sdl_event.gbutton.down; }
intptr_t sdl_gamepad_axis(void)        { return (intptr_t)sdl_event.gaxis.axis; }
intptr_t sdl_gamepad_axis_value(void)  { return (intptr_t)sdl_event.gaxis.value; }

/* SDL_GetGamepads writes the device count through an out-param and returns
   a malloc'd SDL_JoystickID array; both shims below re-call it and free the
   array immediately rather than exposing the raw array across the FFI
   boundary — fine for occasional enumeration (a handful of pads), not
   meant for a hot loop. */
intptr_t sdl_gamepad_count(void) {
    int count = 0;
    SDL_JoystickID *ids = SDL_GetGamepads(&count);
    if (ids) SDL_free(ids);
    return (intptr_t)count;
}

intptr_t sdl_gamepad_id_at(int index) {
    int count = 0;
    SDL_JoystickID *ids = SDL_GetGamepads(&count);
    SDL_JoystickID id = 0;
    if (ids && index >= 0 && index < count) id = ids[index];
    if (ids) SDL_free(ids);
    return (intptr_t)id;
}

/* Touch event fields (SDL_Event.tfinger) — real `float` returns, not the
   intptr_t-cast trick the int-valued accessors above use: these are
   normalized 0..1 (x/y/pressure) or -1..1 (dx/dy) values, and truncating
   through an int cast would collapse almost everything to 0. */
float sdl_touch_x(void)        { return sdl_event.tfinger.x; }
float sdl_touch_y(void)        { return sdl_event.tfinger.y; }
float sdl_touch_dx(void)       { return sdl_event.tfinger.dx; }
float sdl_touch_dy(void)       { return sdl_event.tfinger.dy; }
float sdl_touch_pressure(void) { return sdl_event.tfinger.pressure; }

/* Pen event fields — SDL_PenMotionEvent/TouchEvent/ButtonEvent/AxisEvent
   all share an identical type+reserved+timestamp+windowID+which+pen_state
   prefix followed by x,y at the same offset in all four, so reading
   .pmotion.{x,y} is safe regardless of which of the four the current
   polled event actually is; the trailing fields specific to one event kind
   (eraser/down/button/axis/value) are read from their own struct. */
float    sdl_pen_x(void)           { return sdl_event.pmotion.x; }
float    sdl_pen_y(void)           { return sdl_event.pmotion.y; }
intptr_t sdl_pen_down(void)        { return (intptr_t)sdl_event.ptouch.down; }
intptr_t sdl_pen_eraser(void)      { return (intptr_t)sdl_event.ptouch.eraser; }
intptr_t sdl_pen_button(void)      { return (intptr_t)sdl_event.pbutton.button; }
intptr_t sdl_pen_button_down(void) { return (intptr_t)sdl_event.pbutton.down; }
intptr_t sdl_pen_axis(void)        { return (intptr_t)sdl_event.paxis.axis; }
float    sdl_pen_axis_value(void)  { return sdl_event.paxis.value; }

/* Sine-wave "beep" tone: opens one process-lifetime playback stream lazily
   on first use, synthesizes duration_ms of a freq_hz sine wave directly in
   C, and queues it via SDL_PutAudioStreamData. Synthesis happens shim-side
   rather than sample-by-sample from Ruby because Spinel's FFI has no bulk
   float-array-write primitive shaped for raw PCM bytes (:float_array is a
   Spinel Array<Float>'s own storage, not an arbitrary byte buffer — see
   the capabilities/roadmap doc). */
static SDL_AudioStream *sdl_beep_stream = NULL;
#define SDL_BEEP_SAMPLE_RATE 44100

intptr_t sdl_audio_beep(int freq_hz, int duration_ms, int volume_pct) {
    if (!sdl_beep_stream) {
        SDL_AudioSpec spec;
        spec.format = SDL_AUDIO_F32;
        spec.channels = 1;
        spec.freq = SDL_BEEP_SAMPLE_RATE;
        sdl_beep_stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, NULL, NULL);
        if (sdl_beep_stream) SDL_ResumeAudioStreamDevice(sdl_beep_stream);
    }
    if (!sdl_beep_stream || duration_ms <= 0) return 0;

    int n = (SDL_BEEP_SAMPLE_RATE * duration_ms) / 1000;
    if (n <= 0) return 0;
    float *samples = (float *)SDL_malloc(sizeof(float) * (size_t)n);
    if (!samples) return 0;

    int vp = volume_pct < 0 ? 0 : (volume_pct > 100 ? 100 : volume_pct);
    float vol = (float)vp / 100.0f;
    for (int i = 0; i < n; i++) {
        double t = (double)i / (double)SDL_BEEP_SAMPLE_RATE;
        samples[i] = (float)SDL_sin(2.0 * SDL_PI_D * (double)freq_hz * t) * vol;
    }

    bool ok = SDL_PutAudioStreamData(sdl_beep_stream, samples, (int)(sizeof(float) * (size_t)n));
    SDL_free(samples);
    return (intptr_t)ok;
}

/* Milliseconds of already-queued beep audio still waiting to play (mono
   float32 @ 44100 Hz => 4 bytes/sample). */
intptr_t sdl_audio_queued_ms(void) {
    if (!sdl_beep_stream) return 0;
    int bytes = SDL_GetAudioStreamQueued(sdl_beep_stream);
    return (intptr_t)(((int64_t)bytes / 4) * 1000 / SDL_BEEP_SAMPLE_RATE);
}

/* A loaded WAV file, played on its own dedicated audio stream opened at the
   WAV's own native format (SDL_LoadWAV reports it) — so playback never has
   to worry about matching sample rate/channels/format to some other stream
   by hand. One stream per loaded sound is the pattern SDL3 itself
   recommends (multiple streams bound to one physical device are mixed
   internally), not a workaround. */
typedef struct {
    Uint8 *buf;
    Uint32 len;
    SDL_AudioStream *stream;
} SdlWav;

intptr_t sdl_load_wav(const char *path) {
    SDL_AudioSpec spec;
    Uint8 *buf = NULL;
    Uint32 len = 0;
    if (!SDL_LoadWAV(path, &spec, &buf, &len)) return (intptr_t)NULL;

    SdlWav *w = (SdlWav *)SDL_calloc(1, sizeof(SdlWav));
    if (!w) { SDL_free(buf); return (intptr_t)NULL; }
    w->buf = buf;
    w->len = len;
    w->stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, NULL, NULL);
    if (w->stream) SDL_ResumeAudioStreamDevice(w->stream);
    return (intptr_t)w;
}

/* Restarts playback from the beginning: clears whatever was still queued
   from a previous play, then re-queues the whole buffer. */
intptr_t sdl_wav_play(void *wav) {
    SdlWav *w = (SdlWav *)wav;
    if (!w || !w->stream) return 0;
    SDL_ClearAudioStream(w->stream);
    return (intptr_t)SDL_PutAudioStreamData(w->stream, w->buf, (int)w->len);
}

intptr_t sdl_wav_len(void *wav) {
    SdlWav *w = (SdlWav *)wav;
    return w ? (intptr_t)w->len : 0;
}

intptr_t sdl_wav_free(void *wav) {
    SdlWav *w = (SdlWav *)wav;
    if (!w) return 0;
    if (w->stream) SDL_DestroyAudioStream(w->stream);
    if (w->buf) SDL_free(w->buf);
    SDL_free(w);
    return 0;
}

/* SDL_Surface's w/h fields are public (unlike Window/Renderer's opaque
   pointers) but still need a shim accessor since there's no direct
   cross-FFI struct-field read for them here. */
intptr_t sdl_surface_width(SDL_Surface *s)  { return s ? (intptr_t)s->w : 0; }
intptr_t sdl_surface_height(SDL_Surface *s) { return s ? (intptr_t)s->h : 0; }

/* Test-support only, from here down: injects a synthetic event via
   SDL_PushEvent so the touch/pen/gamepad event-field accessors above can
   be exercised deterministically in test/*.rb without real touch/pen/
   gamepad hardware attached. Not used by any production binding code. */
intptr_t sdl_test_push_touch_event(float x, float y, float dx, float dy, float pressure) {
    SDL_Event e;
    SDL_zero(e);
    e.type = SDL_EVENT_FINGER_DOWN;
    e.tfinger.touchID = 1;
    e.tfinger.fingerID = 1;
    e.tfinger.x = x;
    e.tfinger.y = y;
    e.tfinger.dx = dx;
    e.tfinger.dy = dy;
    e.tfinger.pressure = pressure;
    return (intptr_t)SDL_PushEvent(&e);
}

intptr_t sdl_test_push_pen_event(float x, float y, float axis_value) {
    SDL_Event e;
    SDL_zero(e);
    e.type = SDL_EVENT_PEN_AXIS;
    e.paxis.which = 1;
    e.paxis.x = x;
    e.paxis.y = y;
    e.paxis.axis = SDL_PEN_AXIS_PRESSURE;
    e.paxis.value = axis_value;
    return (intptr_t)SDL_PushEvent(&e);
}

intptr_t sdl_test_push_gamepad_button_event(int button, int down) {
    SDL_Event e;
    SDL_zero(e);
    e.type = down ? SDL_EVENT_GAMEPAD_BUTTON_DOWN : SDL_EVENT_GAMEPAD_BUTTON_UP;
    e.gbutton.which = 1;
    e.gbutton.button = (Uint8)button;
    e.gbutton.down = down ? true : false;
    return (intptr_t)SDL_PushEvent(&e);
}

intptr_t sdl_test_push_gamepad_axis_event(int axis, int value) {
    SDL_Event e;
    SDL_zero(e);
    e.type = SDL_EVENT_GAMEPAD_AXIS_MOTION;
    e.gaxis.which = 1;
    e.gaxis.axis = (Uint8)axis;
    e.gaxis.value = (Sint16)value;
    return (intptr_t)SDL_PushEvent(&e);
}
