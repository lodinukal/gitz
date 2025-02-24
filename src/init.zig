const std = @import("std");
const raw = @import("raw.zig");

var git2_init = std.once(libgit2_init);

pub fn init() void {
    git2_init.call();
}

fn libgit2_init() void {
    const rc = raw.git_libgit2_init();
    if (rc >= 0) return;

    const git_error = raw.git_error_last();
    std.debug.panic("could not initialize libgit2: ({d}) {s}", .{ rc, git_error.*.message });
}
