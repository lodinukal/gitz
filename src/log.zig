const std = @import("std");

const gitlog = std.log.scoped(.gitz);

pub fn err(comptime format: []const u8, args: anytype) void {
    gitlog.err(format, args);
}

pub fn warn(comptime format: []const u8, args: anytype) void {
    gitlog.warn(format, args);
}

pub fn info(comptime format: []const u8, args: anytype) void {
    gitlog.info(format, args);
}

pub fn debug(comptime format: []const u8, args: anytype) void {
    gitlog.debug(format, args);
}
