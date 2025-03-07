const raw = @import("raw.zig");
const err = @import("error.zig");

const Reference = @import("reference.zig");

const Branch = @This();

pub const Type = enum(u8) {
    Local = 1,
    Remote = 2,
    All = 3,
};

inner: Reference,

pub fn deinit(self: Branch) void {
    self.inner.deinit();
}

pub fn upstream(self: Branch) !Branch {
    var ptr: ?*raw.git_reference = null;
    try err.tryCall("could not get upstream for branch", raw.git_branch_upstream(&ptr, self.inner.rawptr));
    return Branch{ .inner = Reference{ .rawptr = ptr } };
}

pub fn reference(self: Branch) Reference {
    return self.inner;
}
