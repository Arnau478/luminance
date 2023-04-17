const std = @import("std");
const yaml = @import("yaml");

pub const Config = struct {
    window: struct {
        frame: struct {
            width: u32,
            color: []const u8,
        },
        background: []const u8,
    },
    background: []const u8,
    layout: []const u8,
};

fn openConfig() !std.fs.File {
    const path: []const u8 = blk: {
        if (std.os.getenv("XDG_CONFIG_HOME")) |xdg_config_home| {
            break :blk try std.fs.path.join(std.heap.page_allocator, &[_][]const u8{ xdg_config_home, "luminance/config.yml" });
        } else if (std.os.getenv("HOME")) |home| {
            break :blk try std.fs.path.join(std.heap.page_allocator, &[_][]const u8{ home, ".config/luminance/config.yml" });
        } else break :blk "";
    };

    std.debug.print("Loading config from: {s}\n", .{path});

    return std.fs.cwd().openFile(path, std.fs.File.OpenFlags{ .mode = .read_only });
}

pub fn getConfig() !Config {
    var config_file = try openConfig();
    defer config_file.close();

    const source = try config_file.readToEndAlloc(std.heap.page_allocator, std.math.maxInt(u32));

    var untyped = try yaml.Yaml.load(std.heap.page_allocator, source);
    return try untyped.parse(Config);
}
