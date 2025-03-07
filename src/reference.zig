const std = @import("std");

const raw = @import("raw.zig");
const Oid = @import("oid.zig");

const Reference = @This();

pub const Type = enum(u8) {
    /// A reference which points at an object ID.
    Direct,
    /// A reference which points at another reference.
    Symbolic,
    /// Unknown reference type.
    _,
};

rawptr: ?*raw.git_reference,

pub fn deinit(self: Reference) void {
    raw.git_reference_free(self.rawptr);
}

pub fn fromRaw(rawptr: ?*raw.git_reference) Reference {
    return Reference{ .rawptr = rawptr };
}

/// Returns whether the reference is a local branch.
pub fn isBranch(self: Reference) bool {
    return raw.git_reference_is_branch(self.rawptr) == 1;
}

/// Returns whether the reference is a note.
pub fn isNote(self: Reference) bool {
    return raw.git_reference_is_note(self.rawptr) == 1;
}

/// Returns whether the reference is a remote tracking branch.
pub fn isRemote(self: Reference) bool {
    return raw.git_reference_is_remote(self.rawptr) == 1;
}

/// Returns whether the reference is a tag.
pub fn isTag(self: Reference) bool {
    return raw.git_reference_is_tag(self.rawptr) == 1;
}

/// Returns the type of the reference.
pub fn kind(self: Reference) Type {
    const ref_type = raw.git_reference_type(self.rawptr);
    return @enumFromInt(ref_type);
}

/// Returns the full name of the reference.
pub fn name(self: Reference) []const u8 {
    const ptr = raw.git_reference_name(self.rawptr);
    return std.mem.sliceTo(ptr, 0);
}

/// Returns the shorthand name of the reference.
///
/// This will transform the reference name into a human-readable version.
/// If no shortname is appropriate, this will return the full name.
pub fn shorthand(self: Reference) []const u8 {
    const ptr = raw.git_reference_shorthand(self.rawptr);
    return std.mem.sliceTo(ptr, 0);
}

/// Returns the OID pointed to by a direct reference.
///
/// Only available if the reference is direct.
pub fn target(self: Reference) ?Oid {
    const ptr = raw.git_reference_target(self.rawptr);
    if (ptr == null) return null;
    return Oid{ .rawptr = ptr };
}
