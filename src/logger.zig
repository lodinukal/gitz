const std = @import("std");
const builtin = @import("builtin");

const log_scope = std.log.scoped(.gitz);

pub fn err(comptime format: []const u8, args: anytype) void {
    comptime if (!builtin.is_test) {
        log_scope.err(format, args);
    };
}

pub fn warn(comptime format: []const u8, args: anytype) void {
    comptime if (!builtin.is_test) {
        log_scope.warn(format, args);
    };
}

pub fn info(comptime format: []const u8, args: anytype) void {
    comptime if (!builtin.is_test) {
        log_scope.info(format, args);
    };
}

pub fn debug(comptime format: []const u8, args: anytype) void {
    comptime if (!builtin.is_test) {
        log_scope.debug(format, args);
    };
}
