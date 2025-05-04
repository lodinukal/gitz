const std = @import("std");

const err = @import("error.zig");
const init = @import("init.zig");
const raw = @import("raw.zig");

const Branch = @import("branch.zig");
const Oid = @import("oid.zig");
const Reference = @import("reference.zig");
const Statuses = @import("statuses.zig");

const Repository = @This();

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

pub fn deinit(self: Repository) void {
    raw.git_repository_free(self.rawptr);
}

/// Attempts to open an already-existing repository at `repository_path`.
///
/// The path can point to either a normal or a bare repository.
pub fn open(repository_path: []const u8) !Repository {
    init.init();

    var repository: ?*raw.git_repository = null;
    const rc = raw.git_repository_open(&repository, repository_path.ptr);
    if (rc < 0) {
        const git_err = err.GitError.lastError(rc);
        git_err.log("git_repository_open");

        return git_err.toError();
    }

    return Repository{ .rawptr = repository };
}

/// Clones a repository from `url` to `path`.
///
/// The path can point to either a normal or a bare repository.
pub fn clone(
    url: []const u8,
    to: []const u8,
    options: raw.git_clone_options,
) !Repository {
    init.init();

    var repository: ?*raw.git_repository = null;
    const rc = raw.git_clone(&repository, url.ptr, to.ptr, &options);
    if (rc < 0) {
        const git_err = err.GitError.lastError(rc);
        git_err.log("git_clone");

        return git_err.toError();
    }

    return Repository{ .rawptr = repository };
}

/// Attempts to open an alread-existing repository at or above `search_path`
pub fn discover(search_path: [:0]const u8, options: DiscoverOptions) !Repository {
    init.init();

    var root_buf: raw.git_buf = .{};
    try err.tryCall(
        "could not discover repository",
        raw.git_repository_discover(&root_buf, search_path.ptr, @intFromBool(options.acrossFs), null),
    );
    defer raw.git_buf_free(&root_buf);

    var repository: ?*raw.git_repository = null;
    try err.tryCall("could not open repository", raw.git_repository_open(&repository, root_buf.ptr));

    return Repository{ .rawptr = repository };
}

/// Check if the current branch is unborn
///
/// An unborn branch is one named from HEAD but which doesn't exist in the refs namespace, because it doesn't have any commit to point to.
pub fn isHeadUnborn(self: Repository) !bool {
    return try err.tryCallBool("could not check if head is unborn", raw.git_repository_head_unborn(self.rawptr));
}

/// Returns whether this repository is bare or not.
pub fn isBare(self: Repository) bool {
    return raw.git_repository_is_bare(self.rawptr) == 1;
}

/// Returns whether this repository is a shallow clone.
pub fn isShallow(self: Repository) bool {
    return raw.git_repository_is_shallow(self.rawptr) == 1;
}

/// Returns whether this repository is a worktree.
pub fn isWorktree(self: Repository) bool {
    return raw.git_repository_is_worktree(self.rawptr) == 1;
}

/// Returns whether this repository is empty.
///
/// Returns an error if the repository is corrupted.
pub fn isEmpty(self: Repository) !bool {
    return try err.tryCallBool(
        "could not check if repository is empty",
        raw.git_repository_is_empty(self.rawptr),
    );
}

/// Returns the path to the `.git` directory for normal repositories or the
/// repository itself for bare repositories.
pub fn path(self: Repository) []const u8 {
    const ptr = raw.git_repository_path(self.rawptr);
    return std.mem.sliceTo(ptr, 0);
}

/// Returns the path of the shared common directory for this repository.
///
/// If the repository is bare, it is the root directory for the repository.
/// If the repository is a worktree, it is the parent repository's gitdir.
/// Otherwise, it is the gitdir.
pub fn commondir(self: Repository) []const u8 {
    const ptr = raw.git_repository_commondir(self.rawptr);
    return std.mem.sliceTo(ptr, 0);
}

/// Returns the current state of this repository.
pub fn state(self: Repository) State {
    const raw_state = raw.git_repository_state(self.rawptr);
    return @enumFromInt(raw_state);
}

/// Returns the path of the working directory for this repository.
///
/// If the repository is bare, `null` is returned.
pub fn workdir(self: Repository) ?[]const u8 {
    const ptr = raw.git_repository_workdir(self.rawptr);
    if (ptr == null) {
        return null;
    }

    return std.mem.sliceTo(ptr, 0);
}

pub fn head(self: Repository) !Reference {
    var ptr: ?*raw.git_reference = null;
    try err.tryCall(
        "could not get repository head",
        raw.git_repository_head(&ptr, self.rawptr),
    );
    return Reference{ .rawptr = ptr };
}

pub fn findBranch(self: Repository, name: [:0]const u8, branch_type: Branch.Type) !Branch {
    var ptr: ?*raw.git_reference = null;
    try err.tryCall("could not find branch", raw.git_branch_lookup(&ptr, self.rawptr, name.ptr, @intFromEnum(branch_type)));
    return Branch{ .inner = Reference{ .rawptr = ptr } };
}

// TODO: add options
pub fn statuses(self: Repository) !Statuses {
    var ptr: ?*raw.git_status_list = null;
    try err.tryCall("could not gather status list", raw.git_status_list_new(&ptr, self.rawptr, null));
    return Statuses{ .rawptr = ptr };
}

pub fn graphAheadBehind(self: Repository, local: Oid, upstream: Oid) !struct { usize, usize } {
    var ahead: usize = 0;
    var behind: usize = 0;

    try err.tryCall("could not graph ahead/behind", raw.git_graph_ahead_behind(&ahead, &behind, self.rawptr, local.rawptr, upstream.rawptr));

    return .{ ahead, behind };
}

const testing = std.testing;

test "open error" {
    try testing.expectError(err.Error.NotFound, Repository.open("harness/does/not/exist"));
    try testing.expectError(err.Error.NotFound, Repository.open("harness/notgit"));
    try testing.expectError(err.Error.NotFound, Repository.open("harness/corrupted"));
}

test "bare repository" {
    var repository = try Repository.open("harness/bare");
    defer repository.deinit();

    try testing.expect(repository.isBare());

    const cwd = try std.process.getCwdAlloc(testing.allocator);
    defer testing.allocator.free(cwd);
    const expected_path = try std.fmt.allocPrint(testing.allocator, "{s}/harness/bare/", .{cwd});
    defer testing.allocator.free(expected_path);

    try testing.expectEqualStrings(expected_path, repository.path());

    try testing.expectEqual(null, repository.workdir());
}

test "empty repository" {
    var repository = try Repository.open("harness/empty");
    defer repository.deinit();

    try testing.expect(!repository.isBare());
    try testing.expect(try repository.isEmpty());

    try testing.expect(try repository.isHeadUnborn());
    try testing.expectError(err.Error.UnbornBranch, repository.head());

    const cwd = try std.process.getCwdAlloc(testing.allocator);
    defer testing.allocator.free(cwd);
    const expected_workdir = try std.fmt.allocPrint(testing.allocator, "{s}/harness/empty/", .{cwd});
    defer testing.allocator.free(expected_workdir);

    try testing.expectEqualStrings(expected_workdir, repository.workdir().?);

    const expected_path = try std.fmt.allocPrint(testing.allocator, "{s}.git/", .{expected_workdir});
    defer testing.allocator.free(expected_path);

    try testing.expectEqualStrings(expected_path, repository.path());
}

test "discover repository" {
    var repository = try Repository.discover("harness/discover/sub/dir/ect/ory", .{});
    defer repository.deinit();

    const cwd = try std.process.getCwdAlloc(testing.allocator);
    defer testing.allocator.free(cwd);
    const expected_workdir = try std.fmt.allocPrint(testing.allocator, "{s}/harness/discover/", .{cwd});
    defer testing.allocator.free(expected_workdir);

    try testing.expectEqualStrings(expected_workdir, repository.workdir().?);

    const expected_path = try std.fmt.allocPrint(testing.allocator, "{s}.git/", .{expected_workdir});
    defer testing.allocator.free(expected_path);

    try testing.expectEqualStrings(expected_path, repository.path());
}

test "helloworld repository" {
    var repository = try Repository.open("harness/helloworld");
    defer repository.deinit();

    try testing.expect(!repository.isBare());
    try testing.expect(!(try repository.isEmpty()));
    try testing.expect(!(try repository.isHeadUnborn()));

    const head_ref = try repository.head();

    try testing.expect(head_ref.isBranch());
    try testing.expectEqual(.Symbolic, head_ref.kind());
    try testing.expectEqualStrings("refs/heads/master", head_ref.name());
    try testing.expectEqualStrings("master", head_ref.shorthand());

    const target = head_ref.target().?;

    try testing.expectEqualStrings("7fd1a60b01f91b314f59955a4e4d4e80d8edf11d\x00", &target.toString());
}

test "helloworld_detached repository" {
    var repository = try Repository.open("harness/helloworld_detached");
    defer repository.deinit();

    try testing.expect(!repository.isBare());
    try testing.expect(!(try repository.isEmpty()));
    try testing.expect(!(try repository.isHeadUnborn()));

    const head_ref = try repository.head();

    try testing.expect(!head_ref.isBranch());
    try testing.expectEqual(.Symbolic, head_ref.kind());
    try testing.expectEqualStrings("HEAD", head_ref.name());
    try testing.expectEqualStrings("HEAD", head_ref.shorthand());

    const target = head_ref.target().?;

    try testing.expectEqualStrings("7fd1a60b01f91b314f59955a4e4d4e80d8edf11d\x00", &target.toString());
}
