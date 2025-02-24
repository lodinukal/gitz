const std = @import("std");
const init = @import("init.zig");
const raw = @import("raw.zig");
const gitlog = @import("log.zig");

pub const ErrorCode = enum(i8) {
    /// Generic error
    Generic = raw.GIT_ERROR,
    /// Requested object could not be found
    NotFound = raw.GIT_ENOTFOUND,
    /// Object exists preventing operation
    Exists = raw.GIT_EEXISTS,
    /// More than one object matches
    Ambiguous = raw.GIT_EAMBIGUOUS,
    /// Output buffer too short to hold data
    BufferSize = raw.GIT_EBUFS,
    /// User-generated error
    User = raw.GIT_EUSER,
    /// Operation not allowed on bare repository
    BareRepo = raw.GIT_EBAREREPO,
    /// HEAD refers to branch with no commits
    UnbornBranch = raw.GIT_EUNBORNBRANCH,
    /// Merge in progress prevented operation
    Unmerged = raw.GIT_EUNMERGED,
    /// Reference was not fast-forwardable
    NonFastForward = raw.GIT_ENONFASTFORWARD,
    /// Name/ref spec was not in a valid format
    InvalidSpec = raw.GIT_EINVALIDSPEC,
    /// Checkout conflicts prevented operation
    Conflict = raw.GIT_ECONFLICT,
    /// Lock file prevented operation
    Locked = raw.GIT_ELOCKED,
    /// Reference value does not match expected
    Modified = raw.GIT_EMODIFIED,
    /// Authentication error
    Auth = raw.GIT_EAUTH,
    /// Server certificate is invalid
    Certificate = raw.GIT_ECERTIFICATE,
    /// Patch/merge has already been applied
    Applied = raw.GIT_EAPPLIED,
    /// The requested peel operation is not possible
    Peel = raw.GIT_EPEEL,
    /// Unexpected EOF
    Eof = raw.GIT_EEOF,
    /// Invalid operation or input
    Invalid = raw.GIT_EINVALID,
    /// Uncommitted changes in index prevented operation
    Uncommitted = raw.GIT_EUNCOMMITTED,
    /// The operation is not valid for a directory
    Directory = raw.GIT_EDIRECTORY,
    /// A merge conflict exists and cannot continue
    MergeConflict = raw.GIT_EMERGECONFLICT,
    /// A user-configured callback refused to act
    Passthrough = raw.GIT_PASSTHROUGH,
    /// Signals end of iteration with iterator
    Iterover = raw.GIT_ITEROVER,
    /// Internal only
    Retry = raw.GIT_RETRY,
    /// Hashsum mismatch in object
    Mismatch = raw.GIT_EMISMATCH,
    /// Unsaved changes in the index would be overwritten
    IndexDirty = raw.GIT_EINDEXDIRTY,
    /// Patch application failed
    ApplyFail = raw.GIT_EAPPLYFAIL,
    /// The object is not owned by the current user
    Owner = raw.GIT_EOWNER,
    /// The operation timed out
    Timeout = raw.GIT_TIMEOUT,
    /// There were no changes
    Unchanged = raw.GIT_EUNCHANGED,
    /// An option is not supported
    NotSupported = raw.GIT_ENOTSUPPORTED,
    /// The subject is read-only
    Readonly = raw.GIT_EREADONLY,
};

pub const ErrorClass = enum(u8) {
    None = 0,
    NoMemory = 1,
    Os = 2,
    Invalid = 3,
    Reference = 4,
    Zlib = 5,
    Repository = 6,
    Config = 7,
    Regex = 8,
    Odb = 9,
    Index = 10,
    Object = 11,
    Net = 12,
    Tag = 13,
    Tree = 14,
    Indexer = 15,
    Ssl = 16,
    Submodule = 17,
    Thread = 18,
    Stash = 19,
    Checkout = 20,
    FetchHead = 21,
    Merge = 22,
    Ssh = 23,
    Filter = 24,
    Revert = 25,
    Callback = 26,
    CherryPick = 27,
    Describe = 28,
    Rebase = 29,
    Filesystem = 30,
    Patch = 31,
    Worktree = 32,
    Sha = 33,
    Http = 34,
    Internal = 35,
    Grafts = 36,
};

pub const Error = error{
    Generic,
    NotFound,
    Exists,
    Ambiguous,
    BufferSize,
    User,
    BareRepo,
    UnbornBranch,
    Unmerged,
    NonFastForward,
    InvalidSpec,
    Conflict,
    Locked,
    Modified,
    Auth,
    Certificate,
    Applied,
    Peel,
    Eof,
    Invalid,
    Uncommitted,
    Directory,
    MergeConflict,
    Passthrough,
    Iterover,
    Retry,
    Mismatch,
    IndexDirty,
    ApplyFail,
    Owner,
    Timeout,
    Unchanged,
    NotSupported,
    Readonly,
};

pub const GitError = struct {
    const Self = @This();

    raw_code: c_int,
    raw_klass: c_int,
    message: []const u8,

    pub fn lastError(raw_code: c_int) Self {
        init.init();

        const ptr = raw.git_error_last();

        return Self.fromRaw(raw_code, ptr);
    }

    pub fn fromRaw(raw_code: c_int, rawptr: [*c]const raw.git_error) Self {
        return Self{
            .raw_code = raw_code,
            .raw_klass = rawptr.*.klass,
            .message = std.mem.sliceTo(rawptr.*.message, 0),
        };
    }

    pub fn code(self: Self) ErrorCode {
        return @enumFromInt(self.raw_code);
    }

    pub fn class(self: Self) ErrorClass {
        return @enumFromInt(self.raw_klass);
    }

    pub fn toError(self: Self) Error {
        return switch (self.code()) {
            .Generic => Error.Generic,
            .NotFound => Error.NotFound,
            .Exists => Error.Exists,
            .Ambiguous => Error.Ambiguous,
            .BufferSize => Error.BufferSize,
            .User => Error.User,
            .BareRepo => Error.BareRepo,
            .UnbornBranch => Error.UnbornBranch,
            .Unmerged => Error.Unmerged,
            .NonFastForward => Error.NonFastForward,
            .InvalidSpec => Error.InvalidSpec,
            .Conflict => Error.Conflict,
            .Locked => Error.Locked,
            .Modified => Error.Modified,
            .Auth => Error.Auth,
            .Certificate => Error.Certificate,
            .Applied => Error.Applied,
            .Peel => Error.Peel,
            .Eof => Error.Eof,
            .Invalid => Error.Invalid,
            .Uncommitted => Error.Uncommitted,
            .Directory => Error.Directory,
            .MergeConflict => Error.MergeConflict,
            .Passthrough => Error.Passthrough,
            .Iterover => Error.Iterover,
            .Retry => Error.Retry,
            .Mismatch => Error.Mismatch,
            .IndexDirty => Error.IndexDirty,
            .ApplyFail => Error.ApplyFail,
            .Owner => Error.Owner,
            .Timeout => Error.Timeout,
            .Unchanged => Error.Unchanged,
            .NotSupported => Error.NotSupported,
            .Readonly => Error.Readonly,
        };
    }

    pub fn log(self: Self, message: []const u8) void {
        gitlog.err("{s}: code({d})={} class({d})={} {s}", .{
            message,
            self.raw_code,
            self.code(),
            self.raw_klass,
            self.class(),
            self.message,
        });
    }
};

pub fn tryCall(message: []const u8, rc: c_int) !void {
    if (rc < 0) {
        const git_err = GitError.lastError(rc);
        git_err.log(message);
        return git_err.toError();
    }
}

pub fn tryCallBool(message: []const u8, rc: c_int) !bool {
    if (rc < 0) {
        const git_err = GitError.lastError(rc);
        git_err.log(message);
        return git_err.toError();
    }

    return rc == 1;
}
