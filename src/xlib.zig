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

pub fn XCloseDisplay(display: *Display) void {
    _ = c.XCloseDisplay(display);
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

pub fn XGetWindowAttributes(display: *Display, w: Window, window_attributes_return: *XWindowAttributes) void {
    _ = c.XGetWindowAttributes(display, w, window_attributes_return);
}

pub fn XSetWindowBackground(display: *Display, w: Window, color: u64) void {
    _ = c.XSetWindowBackground(display, w, color);
}

pub fn XCreateSimpleWindow(display: *Display, parent: Window, x: c_int, y: c_int, width: i32, height: i32, border_width: u32, border: u64, background: u64) Window {
    return c.XCreateSimpleWindow(display, parent, x, y, @intCast(c_uint, width), @intCast(c_uint, height), border_width, border, background);
}

pub fn XDestroyWindow(display: *Display, w: Window) void {
    _ = c.XDestroyWindow(display, w);
}

pub fn XAddToSaveSet(display: *Display, w: Window) void {
    _ = c.XAddToSaveSet(display, w);
}

pub fn XRemoveFromSaveSet(display: *Display, w: Window) void {
    _ = c.XRemoveFromSaveSet(display, w);
}

pub fn XReparentWindow(display: *Display, w: Window, parent: Window, x: i32, y: i32) void {
    _ = c.XReparentWindow(display, w, parent, x, y);
}

pub fn XMapWindow(display: *Display, w: Window) void {
    _ = c.XMapWindow(display, w);
}

pub fn XUnmapWindow(display: *Display, w: Window) void {
    _ = c.XUnmapWindow(display, w);
}

pub fn XGrabServer(display: *Display) void {
    _ = c.XGrabServer(display);
}

pub fn XUngrabServer(display: *Display) void {
    _ = c.XUngrabServer(display);
}

pub fn XQueryTree(display: *Display, w: Window, root_return: *Window, parent_return: *Window, children_return: *[*]Window, nchildren_return: *u32) void {
    _ = c.XQueryTree(display, w, root_return, parent_return, @ptrCast([*c][*c]Window, children_return), nchildren_return);
}

pub fn XFree(data: anytype) void {
    _ = c.XFree(@ptrCast(?*anyopaque, data));
}

pub fn XGrabKey(display: *Display, keycode: i32, modifiers: c_uint, grab_window: Window, owner_events: bool, pointer_mode: i32, keyboard_mode: i32) void {
    _ = c.XGrabKey(display, keycode, modifiers, grab_window, @boolToInt(owner_events), pointer_mode, keyboard_mode);
}

pub fn XKeysymToKeycode(display: *Display, keysym: KeySym) KeyCode {
    return c.XKeysymToKeycode(display, keysym);
}

pub fn XGetWMProtocols(display: *Display, w: Window, protocols_return: *[*]Atom, count_return: *u32) void {
    _ = c.XGetWMProtocols(display, w, @ptrCast([*c][*c]Atom, protocols_return), @ptrCast([*c]c_int, count_return));
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

pub fn XClearWindow(display: *Display, w: Window) void {
    _ = c.XClearWindow(display, w);
}
