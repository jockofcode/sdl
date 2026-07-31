#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
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
