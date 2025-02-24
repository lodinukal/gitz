const std = @import("std");
const err = @import("error.zig");
const init = @import("init.zig");
const raw = @import("raw.zig");

pub const Repository = struct {
    const Self = @This();

    pub const State = enum(u8) {
        None = 0,
        Merge = 1,
        Revert = 2,
        RevertSequence = 3,
        CherryPick = 4,
        CherryPickSequence = 5,
        Bisect = 6,
        Rebase = 7,
        RebaseInteractive = 8,
        RebaseMerge = 9,
        ApplyMailbox = 10,
        ApplyMailboxOrRebase = 11,
    };

    // TODO: ceiling dirs?
    pub const DiscoverOptions = struct {
        acrossFs: bool = false,
    };

    rawptr: ?*raw.git_repository,

    pub fn deinit(self: Self) void {
        raw.git_repository_free(self.rawptr);
    }

    /// Attempts to open an already-existing repository at `repository_path`.
    ///
    /// The path can point to either a normal or a bare repository.
    pub fn open(repository_path: []const u8) !Self {
        init.init();

        var repository: ?*raw.git_repository = null;
        const rc = raw.git_repository_open(&repository, repository_path.ptr);
        if (rc < 0) {
            const git_err = err.GitError.lastError(rc);
            git_err.log("git_repository_open");

            return git_err.toError();
        }

        return Self{ .rawptr = repository };
    }

    /// Attempts to open an alread-existing repository at or above `search_path`
    pub fn discover(search_path: []const u8, options: DiscoverOptions) !Self {
        init.init();

        var root_buf: raw.git_buf = .{};
        try err.tryCall(
            "could not discover repository",
            raw.git_repository_discover(&root_buf, search_path.ptr, @intFromBool(options.acrossFs), null),
        );
        defer raw.git_buf_free(&root_buf);

        var repository: ?*raw.git_repository = null;
        try err.tryCall("could not open repository", raw.git_repository_open(&repository, root_buf.ptr));

        return Self{ .rawptr = repository };
    }

    /// Check if the current branch is unborn
    ///
    /// An unborn branch is one named from HEAD but which doesn't exist in the refs namespace, because it doesn't have any commit to point to.
    pub fn isHeadUnborn(self: Self) !bool {
        return try err.tryCallBool("could not check if head is unborn", raw.git_repository_head_unborn(self.rawptr));
    }

    /// Returns whether this repository is bare or not.
    pub fn isBare(self: Self) bool {
        return raw.git_repository_is_bare(self.rawptr) == 1;
    }

    /// Returns whether this repository is a shallow clone.
    pub fn isShallow(self: Self) bool {
        return raw.git_repository_is_shallow(self.rawptr) == 1;
    }

    /// Returns whether this repository is a worktree.
    pub fn isWorktree(self: Self) bool {
        return raw.git_repository_is_worktree(self.rawptr) == 1;
    }

    /// Returns whether this repository is empty.
    ///
    /// Returns an error if the repository is corrupted.
    pub fn isEmpty(self: Self) !bool {
        return try err.tryCallBool(
            "could not check if repository is empty",
            raw.git_repository_is_empty(self.rawptr),
        );
    }

    /// Returns the path to the `.git` directory for normal repositories or the
    /// repository itself for bare repositories.
    pub fn path(self: Self) []const u8 {
        const ptr = raw.git_repository_path(self.rawptr);
        return std.mem.sliceTo(ptr, 0);
    }

    /// Returns the path of the shared common directory for this repository.
    ///
    /// If the repository is bare, it is the root directory for the repository.
    /// If the repository is a worktree, it is the parent repository's gitdir.
    /// Otherwise, it is the gitdir.
    pub fn commondir(self: Self) []const u8 {
        const ptr = raw.git_repository_commondir(self.rawptr);
        return std.mem.sliceTo(ptr, 0);
    }

    /// Returns the current state of this repository.
    pub fn state(self: Self) State {
        const raw_state = raw.git_repository_state(self.rawptr);
        return @enumFromInt(raw_state);
    }

    /// Returns the path of the working directory for this repository.
    ///
    /// If the repository is bare, `null` is returned.
    pub fn workdir(self: Self) ?[]const u8 {
        const ptr = raw.git_repository_workdir(self.rawptr);
        if (ptr == null) {
            return null;
        }

        return std.mem.sliceTo(ptr, 0);
    }

    pub fn head(self: Self) !Reference {
        var ptr: ?*raw.git_reference = null;
        try err.tryCall(
            "could not get repository head",
            raw.git_repository_head(&ptr, self.rawptr),
        );
        return Reference{ .rawptr = ptr };
    }

    pub fn findBranch(self: Self, name: []const u8, branch_type: Branch.Type) !Branch {
        var ptr: ?*raw.git_reference = null;
        try err.tryCall("could not find branch", raw.git_branch_lookup(&ptr, self.rawptr, name.ptr, @intFromEnum(branch_type)));
        return Branch{ .inner = Reference{ .rawptr = ptr } };
    }

    // TODO: add options
    pub fn statuses(self: Self) !Statuses {
        var ptr: ?*raw.git_status_list = null;
        try err.tryCall("could not gather status list", raw.git_status_list_new(&ptr, self.rawptr, null));
        return Statuses{ .rawptr = ptr };
    }

    pub fn graphAheadBehind(self: Self, local: Oid, upstream: Oid) !struct { usize, usize } {
        var ahead: usize = 0;
        var behind: usize = 0;

        try err.tryCall("could not graph ahead/behind", raw.git_graph_ahead_behind(&ahead, &behind, self.rawptr, local.rawptr, upstream.rawptr));

        return .{ ahead, behind };
    }
};

pub const Reference = struct {
    const Self = @This();

    pub const Type = enum(u8) {
        /// A reference which points at an object ID.
        Direct,
        /// A reference which points at another reference.
        Symbolic,
        /// Unknown reference type.
        _,
    };

    rawptr: ?*raw.git_reference,

    pub fn deinit(self: Self) void {
        raw.git_reference_free(self.rawptr);
    }

    pub fn fromRaw(rawptr: ?*raw.git_reference) Self {
        return Self{ .rawptr = rawptr };
    }

    /// Returns whether the reference is a local branch.
    pub fn isBranch(self: Self) bool {
        return raw.git_reference_is_branch(self.rawptr) == 1;
    }

    /// Returns whether the reference is a note.
    pub fn isNote(self: Self) bool {
        return raw.git_reference_is_note(self.rawptr) == 1;
    }

    /// Returns whether the reference is a remote tracking branch.
    pub fn isRemote(self: Self) bool {
        return raw.git_reference_is_remote(self.rawptr) == 1;
    }

    /// Returns whether the reference is a tag.
    pub fn isTag(self: Self) bool {
        return raw.git_reference_is_tag(self.rawptr) == 1;
    }

    /// Returns the type of the reference.
    pub fn kind(self: Self) Type {
        const ref_type = raw.git_reference_type(self.rawptr);
        return @enumFromInt(ref_type);
    }

    /// Returns the full name of the reference.
    pub fn name(self: Self) []const u8 {
        const ptr = raw.git_reference_name(self.rawptr);
        return std.mem.sliceTo(ptr, 0);
    }

    /// Returns the shorthand name of the reference.
    ///
    /// This will transform the reference name into a human-readable version.
    /// If no shortname is appropriate, this will return the full name.
    pub fn shorthand(self: Self) []const u8 {
        const ptr = raw.git_reference_shorthand(self.rawptr);
        return std.mem.sliceTo(ptr, 0);
    }

    /// Returns the OID pointed to by a direct reference.
    ///
    /// Only available if the reference is direct.
    pub fn target(self: Self) ?Oid {
        const ptr = raw.git_reference_target(self.rawptr);
        if (ptr == null) return null;
        return Oid{ .rawptr = ptr };
    }
};

pub const Oid = struct {
    const Self = @This();

    rawptr: *const raw.git_oid,

    /// Returns the Oid formatted as a hex-encoded string.
    pub fn toString(self: Self) [raw.GIT_OID_HEXSZ + 1]u8 {
        var out: [raw.GIT_OID_HEXSZ + 1]u8 = undefined;
        _ = raw.git_oid_tostr(out[0..].ptr, out.len, self.rawptr);
        return out;
    }

    pub fn asBytes(self: Self) []const u8 {
        return self.rawptr.id[0..];
    }

    pub fn isZero(self: Self) bool {
        return raw.git_oid_is_zero(self.rawptr) == 1;
    }
};

pub const Statuses = struct {
    const Self = @This();

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

    pub fn deinit(self: Self) void {
        raw.git_status_list_free(self.rawptr);
    }

    pub fn get(self: Self, idx: usize) ?Entry {
        const ptr = raw.git_status_byindex(self.rawptr, idx);
        if (ptr == null) return null;
        return Entry{ .rawptr = ptr };
    }

    pub fn len(self: Self) usize {
        return raw.git_status_list_entrycount(self.rawptr);
    }

    pub fn isEmpty(self: Self) bool {
        return self.len() == 0;
    }

    pub fn iterator(self: Self) Iterator {
        return Iterator{
            .statuses = self,
            .len = self.len(),
        };
    }
};

pub const Branch = struct {
    const Self = @This();

    pub const Type = enum(u8) {
        Local = 1,
        Remote = 2,
        All = 3,
    };

    inner: Reference,

    pub fn deinit(self: Self) void {
        self.inner.deinit();
    }

    pub fn upstream(self: Self) !Self {
        var ptr: ?*raw.git_reference = null;
        try err.tryCall("could not get upstream for branch", raw.git_branch_upstream(&ptr, self.inner.rawptr));
        return Branch{ .inner = Reference{ .rawptr = ptr } };
    }

    pub fn reference(self: Self) Reference {
        return self.inner;
    }
};
