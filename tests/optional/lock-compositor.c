#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <drm_fourcc.h>
#include <wayland-server-core.h>
#include <wlr/backend.h>
#include <wlr/backend/headless.h>
#include <wlr/render/pixman.h>
#include <wlr/render/allocator.h>
#include <wlr/render/wlr_renderer.h>
#include <wlr/render/wlr_texture.h>
#include <wlr/types/wlr_compositor.h>
#include <wlr/types/wlr_output.h>
#include <wlr/types/wlr_session_lock_v1.h>
#include <wlr/types/wlr_subcompositor.h>
#include <wlr/types/wlr_xdg_shell.h>

/* Headless test server only: it never connects to a compositor. */
static struct wl_listener new_lock_listener, lock_surface_listener;
static struct wl_listener unlock_listener, lock_destroy_listener, surface_commit_listener;
static int lock_active, surface_active;
static struct wlr_surface *active_surface;
static struct wl_event_source *frame_timer;

static int tick_frame(void *data) {
    (void)data;
    if (active_surface) {
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        wlr_surface_send_frame_done(active_surface, &now);
    }
    wl_event_source_timer_update(frame_timer, 16);
    return 0;
}

static void on_surface_commit(struct wl_listener *listener, void *data) {
    (void)listener;
    struct wlr_surface *surface = data;
    struct wlr_texture *texture = wlr_surface_get_texture(surface);
    if (!texture || texture->width != 800 || texture->height != 600) return;
    uint32_t *pixels = calloc(800 * 600, sizeof(uint32_t));
    struct wlr_texture_read_pixels_options options = {
        .data = pixels, .format = DRM_FORMAT_ARGB8888, .stride = 800 * 4,
    };
    if (pixels && wlr_texture_read_pixels(texture, &options)) {
        const char *path = getenv("NOTCH_TEST_FRAME");
        FILE *file = path ? fopen(path, "wb") : NULL;
        if (file) {
            fwrite(pixels, sizeof(uint32_t), 800 * 600, file);
            fclose(file);
        }
    }
    free(pixels);
}

static void on_lock_destroy(struct wl_listener *listener, void *data) {
    (void)data;
    wl_list_remove(&lock_surface_listener.link);
    wl_list_remove(&unlock_listener.link);
    if (surface_active) {
        wl_list_remove(&surface_commit_listener.link);
        surface_active = 0;
        active_surface = NULL;
    }
    wl_list_remove(&listener->link);
    lock_active = 0;
}

static void on_unlock(struct wl_listener *listener, void *data) {
    (void)listener;
    (void)data;
}

static void on_lock_surface(struct wl_listener *listener, void *data) {
    (void)listener;
    struct wlr_session_lock_surface_v1 *lock_surface = data;
    active_surface = lock_surface->surface;
    surface_commit_listener.notify = on_surface_commit;
    wl_signal_add(&lock_surface->surface->events.commit, &surface_commit_listener);
    surface_active = 1;
    wlr_session_lock_surface_v1_configure(lock_surface, 800, 600);
}

static void on_new_lock(struct wl_listener *listener, void *data) {
    (void)listener;
    struct wlr_session_lock_v1 *lock = data;
    if (lock_active) {
        wlr_session_lock_v1_destroy(lock);
        return;
    }
    lock_active = 1;
    lock_surface_listener.notify = on_lock_surface;
    wl_signal_add(&lock->events.new_surface, &lock_surface_listener);
    unlock_listener.notify = on_unlock;
    wl_signal_add(&lock->events.unlock, &unlock_listener);
    lock_destroy_listener.notify = on_lock_destroy;
    wl_signal_add(&lock->events.destroy, &lock_destroy_listener);
    wlr_session_lock_v1_send_locked(lock);
}

int main(void) {
    const char *runtime = getenv("XDG_RUNTIME_DIR");
    const char *display_name = getenv("WAYLAND_DISPLAY");
    if (!runtime || !display_name || strcmp(display_name, "notch-test") != 0) return 8;
    struct wl_display *display = wl_display_create();
    if (!display) return 1;
    frame_timer = wl_event_loop_add_timer(wl_display_get_event_loop(display), tick_frame, NULL);
    if (!frame_timer || wl_event_source_timer_update(frame_timer, 16) != 0) return 1;
    struct wlr_backend *backend = wlr_headless_backend_create(wl_display_get_event_loop(display));
    struct wlr_renderer *renderer = wlr_pixman_renderer_create();
    if (!backend || !renderer || !wlr_renderer_init_wl_display(renderer, display)) return 2;
    struct wlr_allocator *allocator = wlr_allocator_autocreate(backend, renderer);
    if (!allocator || !wlr_compositor_create(display, 6, renderer) ||
        !wlr_subcompositor_create(display) || !wlr_xdg_shell_create(display, 3)) return 3;
    struct wlr_session_lock_manager_v1 *manager = wlr_session_lock_manager_v1_create(display);
    if (!manager) return 4;
    new_lock_listener.notify = on_new_lock;
    wl_signal_add(&manager->events.new_lock, &new_lock_listener);
    struct wlr_output *output = wlr_headless_add_output(backend, 800, 600);
    if (!output || !wlr_output_init_render(output, allocator, renderer)) return 5;
    struct wlr_output_state state;
    wlr_output_state_init(&state);
    wlr_output_state_set_enabled(&state, true);
    wlr_output_state_set_custom_mode(&state, 800, 600, 60000);
    if (!wlr_output_commit_state(output, &state)) return 6;
    wlr_output_state_finish(&state);
    wlr_output_create_global(output, display);
    if (wl_display_add_socket(display, "notch-test") != 0 || !wlr_backend_start(backend)) return 7;
    puts("isolated: ready");
    fflush(stdout);
    wl_display_run(display);
    return 0;
}
