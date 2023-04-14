const std = @import("std");
const xlib = @import("xlib.zig");

var display: *xlib.Display = undefined;
var root: xlib.Window = undefined;

var clients = std.AutoHashMap(xlib.Window, xlib.Window).init(
    std.heap.page_allocator,
);

fn dummyErrorHandler(_: ?*xlib.Display, _: ?*xlib.XErrorEvent) callconv(.C) c_int {
    return 0;
}

fn onCreateNotify(e: xlib.XCreateWindowEvent) !void {
    std.debug.print("[{any}] was created\n", .{e.window});
}

fn onConfigureRequest(e: xlib.XConfigureRequestEvent) !void {
    std.debug.print("Configure request by [{any}]\n", .{e.window});

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
    if (clients.get(e.window)) |frame_w| {
        std.debug.print("Resize [{any}] to {d},{d}\n", .{ e.window, e.width, e.height });
        xlib.XConfigureWindow(display, frame_w, e.value_mask, &changes);
    }

    xlib.XConfigureWindow(display, e.window, e.value_mask, &changes);
}

fn onMapRequest(e: xlib.XMapRequestEvent) !void {
    std.debug.print("Map request by [{any}]\n", .{e.window});
    try frame(e.window, false);
    try xlib.XMapWindow(display, e.window);
}

fn onUnmapNotify(e: xlib.XUnmapEvent) !void {
    if (e.event == root) {
        std.debug.print("UnmapNotify for [{any}] ignored due to e.event=root\n", .{e.window});
        return;
    }
    std.debug.print("[{any}] was unmapped\n", .{e.window});
    if (clients.contains(e.window)) try unframe(e.window);
}

fn onDestroyNotify(e: xlib.XDestroyWindowEvent) !void {
    std.debug.print("[{any}] was destroyed\n", .{e.window});
}

fn onReparentNotify(e: xlib.XReparentEvent) !void {
    std.debug.print("[{any}] was reparented (parent=[{any}]\n", .{ e.window, e.parent });
}

fn frame(w: xlib.Window, primitive: bool) !void {
    std.debug.print("Framing [{any}]\n", .{w});

    const border_width: u32 = 3;
    const border_color: u64 = 0xff0000;
    const bg_color: u64 = 0x000000;

    var x_window_attrs: xlib.XWindowAttributes = undefined;
    try xlib.XGetWindowAttributes(display, w, &x_window_attrs);

    // Check if it was present before the WM
    if (primitive) {
        // In that case, it may not be visible or have override_redirect set
        if (x_window_attrs.override_redirect != 0 or x_window_attrs.map_state != xlib.IsViewable) return;
    }

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

    std.debug.print("Created [{any}] as a frame for [{any}]\n", .{ frame_w, w });

    xlib.XSelectInput(
        display,
        frame_w,
        xlib.SubstructureRedirectMask | xlib.SubstructureNotifyMask,
    );

    try xlib.XAddToSaveSet(display, w);

    try xlib.XReparentWindow(display, w, frame_w, 0, 0);

    try xlib.XMapWindow(display, frame_w);

    try clients.put(w, frame_w);
    std.debug.print("Updated clients list (len={d})\n", .{clients.count()});
}

fn unframe(w: xlib.Window) !void {
    const frame_w = clients.get(w) orelse return error.UnregisteredWindow;
    std.debug.print("Unframing [{any}] (frame_w=[{any}])\n", .{ w, frame_w });

    try xlib.XUnmapWindow(display, frame_w);

    try xlib.XReparentWindow(display, w, root, 0, 0);

    try xlib.XRemoveFromSaveSet(display, w);

    try xlib.XDestroyWindow(display, frame_w);

    _ = clients.remove(w);
    std.debug.print("Updated clients list (len={d})\n", .{clients.count()});
}

pub fn main() !void {
    display = try xlib.XOpenDisplay(null);
    defer xlib.XCloseDisplay(display) catch {};
    root = xlib.DefaultRootWindow(display);
    std.debug.print("Root window is [{any}]\n", .{root});
    xlib.XSelectInput(display, root, xlib.SubstructureRedirectMask | xlib.SubstructureNotifyMask);
    xlib.XSync(display, false);

    xlib.XSetErrorHandler(dummyErrorHandler);

    // Frame existring windows
    xlib.XGrabServer(display);

    var top_level_windows_ptr: [*]xlib.Window = undefined;
    var top_level_windows_count: u32 = undefined;
    var ret_root: xlib.Window = undefined;
    var ret_parent: xlib.Window = undefined;
    try xlib.XQueryTree(display, root, &ret_root, &ret_parent, &top_level_windows_ptr, &top_level_windows_count);
    var top_level_windows = top_level_windows_ptr[0..top_level_windows_count];

    for (top_level_windows) |win| {
        std.debug.print("About to frame [{any}] as primitive window\n", .{win});
        try frame(win, true);
    }

    xlib.XFree(top_level_windows_ptr);
    xlib.XUngrabServer(display);

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
            xlib.UnmapNotify => {
                try onUnmapNotify(e.xunmap);
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
