const c = @cImport({
    @cInclude("X11/Xlib.h");
});

pub const SubstructureRedirectMask = c.SubstructureRedirectMask;
pub const SubstructureNotifyMask = c.SubstructureNotifyMask;

pub const CreateNotify = c.CreateNotify;
pub const ConfigureRequest = c.ConfigureRequest;
pub const MapRequest = c.MapRequest;
pub const UnmapNotify = c.UnmapNotify;
pub const DestroyNotify = c.DestroyNotify;
pub const ReparentNotify = c.ReparentNotify;

pub const Display = c.Display;
pub const Window = c.Window;
pub const XWindowChanges = c.XWindowChanges;
pub const XWindowAttributes = c.XWindowAttributes;
pub const XEvent = c.XEvent;
pub const XErrorEvent = c.XErrorEvent;
pub const XCreateWindowEvent = c.XCreateWindowEvent;
pub const XConfigureRequestEvent = c.XConfigureRequestEvent;
pub const XMapRequestEvent = c.XMapRequestEvent;
pub const XUnmapEvent = c.XUnmapEvent;
pub const XDestroyWindowEvent = c.XDestroyWindowEvent;
pub const XReparentEvent = c.XReparentEvent;

pub fn XOpenDisplay(display_name: ?[*]const u8) error{XOpenDisplayError}!*Display {
    if (c.XOpenDisplay(display_name)) |display| {
        return display;
    } else return error.XOpenDisplayError;
}

pub fn XCloseDisplay(display: *Display) error{BadGC}!void {
    if (c.XCloseDisplay(display) == c.BadGC) return error.BadGC;
}

pub fn DefaultRootWindow(display: *Display) Window {
    return c.DefaultRootWindow(display);
}

pub fn XSetErrorHandler(handler: *const fn (?*Display, ?*XErrorEvent) callconv(.C) c_int) void {
    _ = c.XSetErrorHandler(handler);
}

pub fn XSelectInput(display: *Display, w: Window, event_mask: c_long) void {
    _ = c.XSelectInput(display, w, event_mask);
}

pub fn XSync(display: *Display, discard: bool) void {
    _ = c.XSync(display, @boolToInt(discard));
}

pub fn XNextEvent(display: *Display, event_return: *XEvent) void {
    _ = c.XNextEvent(display, event_return);
}

pub fn XConfigureWindow(display: *Display, w: Window, value_mask: c_ulong, changes: *XWindowChanges) void {
    _ = c.XConfigureWindow(display, w, @intCast(c_uint, value_mask), changes);
}

pub fn XGetWindowAttributes(display: *Display, w: Window, window_attributes_return: *XWindowAttributes) error{ BadDrawable, BadWindow }!void {
    const ret = c.XGetWindowAttributes(display, w, window_attributes_return);
    if (ret == c.BadDrawable) return error.BadDrawable;
    if (ret == c.BadWindow) return error.BadWindow;
}

pub fn XCreateSimpleWindow(display: *Display, parent: Window, x: c_int, y: c_int, width: i32, height: i32, border_width: u32, border: u64, background: u64) Window {
    return c.XCreateSimpleWindow(display, parent, x, y, @intCast(c_uint, width), @intCast(c_uint, height), border_width, border, background);
}

pub fn XDestroyWindow(display: *Display, w: Window) error{BadWindow}!void {
    if (c.XDestroyWindow(display, w) == c.BadWindow) return error.BadWindow;
}

pub fn XAddToSaveSet(display: *Display, w: Window) error{ BadMatch, BadWindow }!void {
    const ret = c.XAddToSaveSet(display, w);
    if (ret == c.BadMatch) return error.BadMatch;
    if (ret == c.BadWindow) return error.BadWindow;
}

pub fn XRemoveFromSaveSet(display: *Display, w: Window) error{ BadMatch, BadWindow }!void {
    const ret = c.XRemoveFromSaveSet(display, w);
    if (ret == c.BadMatch) return error.BadMatch;
    if (ret == c.BadWindow) return error.BadWindow;
}

pub fn XReparentWindow(display: *Display, w: Window, parent: Window, x: i32, y: i32) error{ BadMatch, BadWindow }!void {
    const ret = c.XReparentWindow(display, w, parent, x, y);
    if (ret == c.BadMatch) return error.BadMatch;
    if (ret == c.BadWindow) return error.BadWindow;
}

pub fn XMapWindow(display: *Display, w: Window) error{BadWindow}!void {
    if (c.XMapWindow(display, w) == c.BadWindow) return error.BadWindow;
}

pub fn XUnmapWindow(display: *Display, w: Window) error{BadWindow}!void {
    if (c.XUnmapWindow(display, w) == c.BadWindow) return error.BadWindow;
}
