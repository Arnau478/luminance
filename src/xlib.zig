const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
});

pub const SubstructureRedirectMask = c.SubstructureRedirectMask;
pub const SubstructureNotifyMask = c.SubstructureNotifyMask;

pub const CreateNotify = c.CreateNotify;
pub const ConfigureRequest = c.ConfigureRequest;
pub const MapRequest = c.MapRequest;
pub const UnmapNotify = c.UnmapNotify;
pub const DestroyNotify = c.DestroyNotify;
pub const ReparentNotify = c.ReparentNotify;
pub const KeyPress = c.KeyPress;
pub const ClientMessage = c.ClientMessage;

pub const IsViewable = c.IsViewable;

pub const GrabModeSync = c.GrabModeSync;
pub const GrabModeAsync = c.GrabModeAsync;

pub const Mod1Mask = c.Mod1Mask;

pub const XK_F4 = c.XK_F4;

pub const Atom = c.Atom;
pub const KeySym = c.KeySym;
pub const KeyCode = c.KeyCode;
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
pub const XKeyPressedEvent = c.XKeyPressedEvent;
pub const XClientMessageEvent = c.XClientMessageEventvent;

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

pub fn XGrabServer(display: *Display) void {
    _ = c.XGrabServer(display);
}

pub fn XUngrabServer(display: *Display) void {
    _ = c.XUngrabServer(display);
}

pub fn XQueryTree(display: *Display, w: Window, root_return: *Window, parent_return: *Window, children_return: *[*]Window, nchildren_return: *u32) error{BadWindow}!void {
    if (c.XQueryTree(display, w, root_return, parent_return, @ptrCast([*c][*c]Window, children_return), nchildren_return) == c.BadWindow) return error.BadWindow;
}

pub fn XFree(data: anytype) void {
    _ = c.XFree(@ptrCast(?*anyopaque, data));
}

pub fn XGrabKey(display: *Display, keycode: i32, modifiers: c_uint, grab_window: Window, owner_events: bool, pointer_mode: i32, keyboard_mode: i32) error{ BadAccess, BadValue, BadWindow }!void {
    var res = c.XGrabKey(display, keycode, modifiers, grab_window, @boolToInt(owner_events), pointer_mode, keyboard_mode);
    if (res == c.BadAccess) return error.BadAccess;
    if (res == c.BadValue) return error.BadValue;
    if (res == c.BadWindow) return error.BadWindow;
}

pub fn XKeysymToKeycode(display: *Display, keysym: KeySym) KeyCode {
    return c.XKeysymToKeycode(display, keysym);
}

pub fn XGetWMProtocols(display: *Display, w: Window, protocols_return: *[*]Atom, count_return: *u32) error{BadWindow}!void {
    if (c.XGetWMProtocols(display, w, @ptrCast([*c][*c]Atom, protocols_return), @ptrCast([*c]c_int, count_return)) == c.BadWindow) return error.BadWindow;
}

pub fn XInternAtom(display: *Display, atom_name: []const u8, only_if_exists: bool) Atom {
    return c.XInternAtom(display, @ptrCast([*c]const u8, atom_name), @boolToInt(only_if_exists));
}

pub fn XSendEvent(display: *Display, w: Window, propagate: bool, event_mask: i64, event_send: *XEvent) void {
    _ = c.XSendEvent(display, w, @boolToInt(propagate), event_mask, event_send);
}

pub fn XKillClient(display: *Display, w: Window) void {
    _ = c.XKillClient(display, w);
}
