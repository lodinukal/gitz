const std = @import("std");

const raw = @import("raw.zig");

const Statuses = @This();

pub const Status = enum(u32) {
    Current = 0,
    IndexNew = (1 << 0),
    IndexModified = (1 << 1),
    IndexDeleted = (1 << 2),
    IndexRenamed = (1 << 3),
    IndexTypechange = (1 << 4),
    WtNew = (1 << 7),
    WtModified = (1 << 8),
    WtDeleted = (1 << 9),
    WtTypechange = (1 << 10),
    WtRenamed = (1 << 11),
    WtUnreadable = (1 << 12),
    Ignored = (1 << 14),
    Conflicted = (1 << 15),
    _,
};

// TODO: head_to_index & index_to_workdir
pub const Entry = struct {
    rawptr: *const raw.git_status_entry,

    pub fn path(self: Entry) []const u8 {
        if (self.rawptr.*.head_to_index == null) {
            return self.rawptr.*.index_to_workdir.old_file.path;
        } else {
            return self.rawptr.*.head_to_index.old_file.path;
        }
    }

    pub fn status(self: Entry) Status {
        return @enumFromInt(self.rawptr.*.status);
    }
};

pub const Iterator = struct {
    statuses: Statuses,
    index: usize = 0,
    len: usize,

    pub fn next(self: *Iterator) ?Entry {
        const index = self.index;
        if (index >= self.len) return null;

        self.index += 1;
        return self.statuses.get(index);
    }
};

rawptr: ?*raw.git_status_list,

pub fn deinit(self: Statuses) void {
    raw.git_status_list_free(self.rawptr);
}

pub fn get(self: Statuses, idx: usize) ?Entry {
    const ptr = raw.git_status_byindex(self.rawptr, idx);
    if (ptr == null) return null;
    return Entry{ .rawptr = ptr };
}

pub fn len(self: Statuses) usize {
    return raw.git_status_list_entrycount(self.rawptr);
}

pub fn isEmpty(self: Statuses) bool {
    return self.len() == 0;
}

pub fn iterator(self: Statuses) Iterator {
    return Iterator{
        .statuses = self,
        .len = self.len(),
    };
}
