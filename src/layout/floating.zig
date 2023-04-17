const std = @import("std");
const main = @import("root");
const xlib = @import("../xlib.zig");
const util = @import("../util.zig");

var display: *xlib.Display = undefined;
var root: xlib.Window = undefined;

var drag_start_pos: struct {
    x: i32,
    y: i32,
} = undefined;

var drag_start_frame_pos: struct {
    x: i32,
    y: i32,
} = undefined;

fn init(d: *xlib.Display, r: xlib.Window) error{LayoutInitError}!void {
    std.debug.print("Floating layout init\n", .{});

    display = d;
    root = r;

    xlib.XGrabButton(display, 1, xlib.Mod1Mask, root, true, xlib.ButtonPressMask, xlib.GrabModeAsync, xlib.GrabModeAsync, xlib.None, xlib.None);
}

fn deinit() error{LayoutDeinitError}!void {
    std.debug.print("Floating layout deinit\n", .{});
}

fn onButtonPress(e: xlib.XButtonEvent) error{OnButtonPressError}!void {
    var frame_w = e.subwindow;

    drag_start_pos = .{ .x = e.x_root, .y = e.y_root };

    var returned_root: xlib.Window = undefined;
    var x: i32 = undefined;
    var y: i32 = undefined;
    var width: u32 = undefined;
    var height: u32 = undefined;
    var border_width: u32 = undefined;
    var depth: u32 = undefined;
    xlib.XGetGeometry(display, frame_w, &returned_root, &x, &y, &width, &height, &border_width, &depth);
    drag_start_frame_pos = .{ .x = x, .y = y };

    xlib.XRaiseWindow(display, frame_w);
}

fn onMotionNotify(e: xlib.XMotionEvent) error{OnMotionNotifyError}!void {
    var diff: struct { x: i32, y: i32 } = .{
        .x = e.x_root - drag_start_pos.x,
        .y = e.y_root - drag_start_pos.y,
    };

    xlib.XMoveWindow(display, e.window, drag_start_frame_pos.x + diff.x, drag_start_frame_pos.y + diff.y);
}

pub const layout: main.Layout = .{
    .name = "floating",
    .init = &init,
    .deinit = &deinit,
    .onButtonPress = &onButtonPress,
    .onMotionNotify = &onMotionNotify,
};
