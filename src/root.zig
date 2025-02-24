const git2 = @cImport({
    @cInclude("git2.h");
});

pub usingnamespace @import("repository.zig");
pub usingnamespace @import("error.zig");
