#include <SDL.h>
#include <stdint.h>

/* Static event buffer — populated by sdl_poll_event(), read by the field accessors. */
static SDL_Event sdl_event;

intptr_t sdl_poll_event(void) {
    return (intptr_t)SDL_PollEvent(&sdl_event);
}

intptr_t sdl_event_type(void) {
    return (intptr_t)sdl_event.type;
}

/* Key event fields */
intptr_t sdl_key_sym(void) { return (intptr_t)sdl_event.key.keysym.sym; }
intptr_t sdl_key_mod(void) { return (intptr_t)sdl_event.key.keysym.mod; }

/* Mouse motion / button fields — check event type to pick the right union member */
intptr_t sdl_mouse_x(void) {
    if (sdl_event.type == SDL_MOUSEMOTION)
        return (intptr_t)sdl_event.motion.x;
    return (intptr_t)sdl_event.button.x;
}

intptr_t sdl_mouse_y(void) {
    if (sdl_event.type == SDL_MOUSEMOTION)
        return (intptr_t)sdl_event.motion.y;
    return (intptr_t)sdl_event.button.y;
}

intptr_t sdl_mouse_button(void)  { return (intptr_t)sdl_event.button.button; }
intptr_t sdl_mouse_clicks(void)  { return (intptr_t)sdl_event.button.clicks; }

/* Mouse wheel fields */
intptr_t sdl_wheel_x(void) { return (intptr_t)sdl_event.wheel.x; }
intptr_t sdl_wheel_y(void) { return (intptr_t)sdl_event.wheel.y; }

/* Window event sub-ID */
intptr_t sdl_window_event_id(void) { return (intptr_t)sdl_event.window.event; }

/* SDL_Rect wrappers — SDL_RenderFillRect / SDL_RenderDrawRect take a struct
   pointer that can't be constructed directly from Ruby, so we build it here. */
intptr_t sdl_render_fill_rect(SDL_Renderer *r, int x, int y, int w, int h) {
    SDL_Rect rect = {x, y, w, h};
    return (intptr_t)SDL_RenderFillRect(r, &rect);
}

intptr_t sdl_render_draw_rect(SDL_Renderer *r, int x, int y, int w, int h) {
    SDL_Rect rect = {x, y, w, h};
    return (intptr_t)SDL_RenderDrawRect(r, &rect);
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
