const std = @import("std");
const gitz = @import("gitz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const repository = try gitz.Repository.open(".");
    defer repository.deinit();
    std.debug.print("hello: {}\n", .{repository});

    const path = repository.path();
    std.debug.print("path: {s}\n", .{path});

    const empty = try repository.isEmpty();
    std.debug.print("empty: {}\n", .{empty});

    const workdir = repository.workdir();
    if (workdir) |wd| std.debug.print("workdir: {s}\n", .{wd});

    const head = try repository.head();
    defer head.deinit();
    const head_name = head.name();
    std.debug.print("head name: {s}\n", .{head_name});
    const head_shorthand = head.shorthand();
    std.debug.print("head shorthand: {s}\n", .{head_shorthand});

    const target = head.target();
    if (target) |t| {
        const str = t.toString();
        std.debug.print("target: {s}\n", .{str});
    }
}
