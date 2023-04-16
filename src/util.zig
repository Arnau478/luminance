const std = @import("std");
const xlib = @import("xlib.zig");

/// Serialize an event, returning its type in string form
pub inline fn eventToString(e: xlib.XEvent) []const u8 {
    const x_event_type_names = [_][]const u8{
        "",
        "",
        "KeyPress",
        "KeyRelease",
        "ButtonPress",
        "ButtonRelease",
        "MotionNotify",
        "EnterNotify",
        "LeaveNotify",
        "FocusIn",
        "FocusOut",
        "KeymapNotify",
        "Expose",
        "GraphicsExpose",
        "NoExpose",
        "VisibilityNotify",
        "CreateNotify",
        "DestroyNotify",
        "UnmapNotify",
        "MapNotify",
        "MapRequest",
        "ReparentNotify",
        "ConfigureNotify",
        "ConfigureRequest",
        "GravityNotify",
        "ResizeRequest",
        "CirculateNotify",
        "CirculateRequest",
        "PropertyNotify",
        "SelectionClear",
        "SelectionRequest",
        "SelectionNotify",
        "ColormapNotify",
        "ClientMessage",
        "MappingNotify",
        "GeneralEvent",
    };

    return x_event_type_names[@intCast(usize, e.type)];
}

/// Transform a string in the form "x123456" to 0x123456 as an u64
pub fn strColor(str: []const u8) !u64 {
    if (str.len != 7) return error.InvalidColor;

    return std.fmt.parseInt(u64, str[1..7], 16);
}
