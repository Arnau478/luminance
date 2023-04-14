const std = @import("std");
const xlib = @import("xlib.zig");
const util = @import("util.zig");

var display: *xlib.Display = undefined;
var root: xlib.Window = undefined;

var clients = std.AutoHashMap(xlib.Window, xlib.Window).init(
    std.heap.page_allocator,
);

/// An error handler that just ignores all errors
fn dummyErrorHandler(_: ?*xlib.Display, _: ?*xlib.XErrorEvent) callconv(.C) c_int {
    return 0;
}

fn onCreateNotify(e: xlib.XCreateWindowEvent) !void {
    std.debug.print("[{any}] was created\n", .{e.window});
}

fn onConfigureRequest(e: xlib.XConfigureRequestEvent) !void {
    std.debug.print("Configure request by [{any}]\n", .{e.window});

    // We don't make any changes
    var changes: xlib.XWindowChanges = .{
        .x = e.x,
        .y = e.y,
        .width = e.width,
        .height = e.height,
        .border_width = e.border_width,
        .sibling = e.above,
        .stack_mode = e.detail,
    };

    // If already framed, we should resize the existing frame
    if (clients.get(e.window)) |frame_w| {
        std.debug.print("Resize [{any}] to {d},{d}\n", .{ e.window, e.width, e.height });
        xlib.XConfigureWindow(display, frame_w, e.value_mask, &changes);
    }

    // Call XConfigureWindow to finally pass the event to the X server
    xlib.XConfigureWindow(display, e.window, e.value_mask, &changes);
}

fn onMapRequest(e: xlib.XMapRequestEvent) !void {
    std.debug.print("Map request by [{any}]\n", .{e.window});

    // When a window is mapped, we should frame it
    try frame(e.window, false);
    // Then, we can pass the request to the X server
    xlib.XMapWindow(display, e.window);
}

fn onUnmapNotify(e: xlib.XUnmapEvent) !void {
    // If we generated it, just ignore it
    if (e.event == root) {
        std.debug.print("UnmapNotify for [{any}] ignored due to e.event=root\n", .{e.window});
        return;
    }

    std.debug.print("[{any}] was unmapped\n", .{e.window});

    // Unframe when unmapped
    if (clients.contains(e.window)) try unframe(e.window);
}

fn onDestroyNotify(e: xlib.XDestroyWindowEvent) !void {
    std.debug.print("[{any}] was destroyed\n", .{e.window});
}

fn onReparentNotify(e: xlib.XReparentEvent) !void {
    std.debug.print("[{any}] was reparented (parent=[{any}]\n", .{ e.window, e.parent });
}

fn onKeyPress(e: xlib.XKeyPressedEvent) !void {
    if (((e.state & xlib.Mod1Mask) != 0) and (e.keycode == xlib.XKeysymToKeycode(display, xlib.XK_F4))) {
        close(e.window);
    }
}

/// Frame a window
fn frame(w: xlib.Window, primitive: bool) !void {
    std.debug.print("Framing [{any}]\n", .{w});

    // Hard-coded values for framing
    // TODO: Change this when config files are a thing
    const border_width: u32 = 3;
    const border_color: u64 = 0xff0000;
    const bg_color: u64 = 0x000000;

    // Get the window attributes
    var x_window_attrs: xlib.XWindowAttributes = undefined;
    xlib.XGetWindowAttributes(display, w, &x_window_attrs);

    // Check if it was present before the WM (a.k.a "primitive" window)
    if (primitive) {
        // In that case, it may not be visible or have override_redirect set
        if (x_window_attrs.override_redirect != 0 or x_window_attrs.map_state != xlib.IsViewable) return;
    }

    // Create the actual frame window
    const frame_w: xlib.Window = xlib.XCreateSimpleWindow(
        display,
        root,
        // Same position
        x_window_attrs.x,
        x_window_attrs.y,
        // Same size
        x_window_attrs.width,
        x_window_attrs.height,
        // Framing configuration
        border_width,
        border_color,
        bg_color,
    );

    std.debug.print("Created [{any}] as a frame for [{any}]\n", .{ frame_w, w });

    // We should activate both SubstructureRedirect and SubstructureNotify for the frame
    xlib.XSelectInput(
        display,
        frame_w,
        xlib.SubstructureRedirectMask | xlib.SubstructureNotifyMask,
    );

    // We add the window to the save set so that it gets restored if the WM stops
    xlib.XAddToSaveSet(display, w);

    // We make the client window a child of the frame window
    xlib.XReparentWindow(display, w, frame_w, 0, 0);

    // Map the frame
    xlib.XMapWindow(display, frame_w);

    // Add to clients list
    try clients.put(w, frame_w);
    std.debug.print("Updated clients list (len={d})\n", .{clients.count()});

    // Grab Keys
    xlib.XGrabKey(
        display,
        xlib.XKeysymToKeycode(display, xlib.XK_F4),
        xlib.Mod1Mask,
        w,
        false,
        xlib.GrabModeAsync,
        xlib.GrabModeAsync,
    );
}

/// Unframe a window
fn unframe(w: xlib.Window) !void {
    const frame_w = clients.get(w) orelse return error.UnregisteredWindow;
    std.debug.print("Unframing [{any}] (frame_w=[{any}])\n", .{ w, frame_w });

    // Unmap the frame
    xlib.XUnmapWindow(display, frame_w);

    // Reparent the client window to the root window again
    // Note: This may fail if the window has already been destroyed by
    // the client, but that's OK, we only care about reparenting it if
    // it's not destroyed yet
    xlib.XReparentWindow(display, w, root, 0, 0);

    // Remove from the save set (we no longer need it to be restored)
    xlib.XRemoveFromSaveSet(display, w);

    // Destroy the frame
    xlib.XDestroyWindow(display, frame_w);

    // Remove from the clients list
    _ = clients.remove(w);
    std.debug.print("Updated clients list (len={d})\n", .{clients.count()});
}

fn close(w: xlib.Window) void {
    std.debug.print("About to close [{any}]\n", .{w});

    // We must detect if the client supports WM_DELETE_WINDOW
    var supported_protocols_ptr: [*]xlib.Atom = undefined;
    var supported_protocols_count: u32 = undefined;
    xlib.XGetWMProtocols(display, w, &supported_protocols_ptr, &supported_protocols_count);
    var supported_protocols = supported_protocols_ptr[0..supported_protocols_count];
    var wm_delete_support: bool = false;
    var wm_delete_window: xlib.Atom = xlib.XInternAtom(display, "WM_DELETE_WINDOW", false);
    var wm_protocols: xlib.Atom = xlib.XInternAtom(display, "WM_PROTOCOLS", false);
    for (supported_protocols) |protocol| {
        if (protocol == wm_delete_window) wm_delete_support = true;
    }

    if (wm_delete_support) {
        std.debug.print("Using WM_DELETE_WINDOW on [{any}] to close it\n", .{w});

        var msg: xlib.XEvent = std.mem.zeroes(xlib.XEvent);
        msg.xclient.type = xlib.ClientMessage;
        msg.xclient.message_type = wm_protocols;
        msg.xclient.window = w;
        msg.xclient.format = 32;
        msg.xclient.data.l[0] = @intCast(c_long, wm_delete_window);
        xlib.XSendEvent(display, w, false, 0, &msg);
    } else {
        std.debug.print("Using XKillClient() on [{any}] to close it\n", .{w});
        xlib.XKillClient(display, w);
    }
}

pub fn main() !void {
    // Open default (null) display
    display = try xlib.XOpenDisplay(null);
    // When we finish, we should close it
    defer xlib.XCloseDisplay(display);

    // Now, get the root window
    root = xlib.DefaultRootWindow(display);
    std.debug.print("Root window is [{any}]\n", .{root});

    // Set SubstructureRedirect and SubstructureNotify for the root window
    xlib.XSelectInput(display, root, xlib.SubstructureRedirectMask | xlib.SubstructureNotifyMask);
    xlib.XSync(display, false);

    // Set the dummy error handler as the default one
    xlib.XSetErrorHandler(dummyErrorHandler);

    // To frame existring windows, first grab the server to ensure consistency
    xlib.XGrabServer(display);
    // Now, call XQueryTree to get them
    var top_level_windows_ptr: [*]xlib.Window = undefined;
    var top_level_windows_count: u32 = undefined;
    var ret_root: xlib.Window = undefined;
    var ret_parent: xlib.Window = undefined;
    xlib.XQueryTree(display, root, &ret_root, &ret_parent, &top_level_windows_ptr, &top_level_windows_count);
    var top_level_windows = top_level_windows_ptr[0..top_level_windows_count];

    // Frame every window detected
    for (top_level_windows) |win| {
        std.debug.print("About to frame [{any}] as primitive window\n", .{win});
        try frame(win, true);
    }

    // We no longer need the list of top-level windows, so free it
    xlib.XFree(top_level_windows_ptr);
    // And ungrab the server to continue normally
    xlib.XUngrabServer(display);

    // Main event loop
    while (true) {
        // Get next event
        var e: xlib.XEvent = undefined;
        xlib.XNextEvent(display, &e);

        std.debug.print(":: {s}\n", .{util.eventToString(e)});

        // And call the respective listener
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
            xlib.KeyPress => {
                try onKeyPress(e.xkey);
            },
            else => {},
        }
    }
}
