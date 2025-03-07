const raw = @import("raw.zig");

const Oid = @This();

rawptr: *const raw.git_oid,

// FIXME: this seems to return a normal slice with a null termination
// byte. Either we drop the last byte in the return value, or we return a
// sentinel-terminated slice, but this is currently incorrect.
/// Returns the Oid formatted as a hex-encoded string.
pub fn toString(self: Oid) [raw.GIT_OID_HEXSZ + 1]u8 {
    var out: [raw.GIT_OID_HEXSZ + 1]u8 = undefined;
    _ = raw.git_oid_tostr(out[0..].ptr, out.len, self.rawptr);
    return out;
}

pub fn asBytes(self: Oid) []const u8 {
    return self.rawptr.id[0..];
}

pub fn isZero(self: Oid) bool {
    return raw.git_oid_is_zero(self.rawptr) == 1;
}
