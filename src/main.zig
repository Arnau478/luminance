const std = @import("std");
const xlib = @import("xlib.zig");

var display: *xlib.Display = undefined;
var root: xlib.Window = undefined;

var clients = std.AutoHashMap(xlib.Window, xlib.Window).init(
    std.heap.page_allocator,
);

fn onCreateNotify(e: xlib.XCreateWindowEvent) !void {
    _ = e;
}

fn onConfigureRequest(e: xlib.XConfigureRequestEvent) !void {
    var changes: xlib.XWindowChanges = .{
        .x = e.x,
        .y = e.y,
        .width = e.width,
        .height = e.height,
        .border_width = e.border_width,
        .sibling = e.above,
        .stack_mode = e.detail,
    };

    // If already framed
    if (clients.getEntry(e.window)) |entry| {
        std.debug.print("Resize [{any}] to {d},{d}", .{ entry.value_ptr.*, e.width, e.height });
        xlib.XConfigureWindow(display, entry.value_ptr.*, e.value_mask, &changes);
    }

    xlib.XConfigureWindow(display, e.window, e.value_mask, &changes);
}

fn onMapRequest(e: xlib.XMapRequestEvent) !void {
    try frame(e.window);
    try xlib.XMapWindow(display, e.window);
}

fn onDestroyNotify(e: xlib.XDestroyWindowEvent) !void {
    _ = e;
}

fn onReparentNotify(e: xlib.XReparentEvent) !void {
    _ = e;
}

fn frame(w: xlib.Window) !void {
    const border_width: u32 = 3;
    const border_color: u64 = 0xff0000;
    const bg_color: u64 = 0x0000ff;

    var x_window_attrs: xlib.XWindowAttributes = undefined;
    try xlib.XGetWindowAttributes(display, w, &x_window_attrs);

    const frame_w: xlib.Window = xlib.XCreateSimpleWindow(
        display,
        root,
        x_window_attrs.x,
        x_window_attrs.y,
        x_window_attrs.width,
        x_window_attrs.height,
        border_width,
        border_color,
        bg_color,
    );

    xlib.XSelectInput(
        display,
        frame_w,
        xlib.SubstructureRedirectMask | xlib.SubstructureNotifyMask,
    );

    try xlib.XAddToSaveSet(display, w);

    try xlib.XReparentWindow(display, w, frame_w, 0, 0);

    try xlib.XMapWindow(display, frame_w);

    try clients.put(w, frame_w);
}

pub fn main() !void {
    display = try xlib.XOpenDisplay(null);
    defer xlib.XCloseDisplay(display) catch {};
    root = xlib.DefaultRootWindow(display);
    xlib.XSelectInput(display, root, xlib.SubstructureRedirectMask | xlib.SubstructureNotifyMask);
    xlib.XSync(display, false);

    while (true) {
        var e: xlib.XEvent = undefined;
        xlib.XNextEvent(display, &e);

        switch (e.type) {
            xlib.CreateNotify => {
                try onCreateNotify(e.xcreatewindow);
            },
            xlib.ConfigureRequest => {
                try onConfigureRequest(e.xconfigurerequest);
            },
            xlib.MapRequest => {
                try onMapRequest(e.xmaprequest);
            },
            xlib.DestroyNotify => {
                try onDestroyNotify(e.xdestroywindow);
            },
            xlib.ReparentNotify => {
                try onReparentNotify(e.xreparent);
            },
            else => {},
        }
    }
}
