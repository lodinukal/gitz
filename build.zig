const std = @import("std");

const TlsBackend = enum { openssl, mbedtls };

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.addModule("gitz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "gitz",
        .root_module = lib_mod,
        .use_llvm = optimize != .Debug,
    });

    const tls_backend = b.option(
        TlsBackend,
        "tls-backend",
        "Choose Unix TLS/SSL backend",
    ) orelse .mbedtls;
    const enable_ssh = b.option(bool, "enable-ssh", "Enable SSH support") orelse false;
    const libgit2 = b.dependency("libgit2", .{
        .target = target,
        .optimize = optimize,
        // This spits out warnings about libssh2 not being neither ET_REL nor
        // LLVM bitcode but I:
        // 1: don't know what that means for now
        // 2: don't really care to investigate since it doesn't seem to actually
        // block the build
        .@"enable-ssh" = enable_ssh,
        .@"tls-backend" = tls_backend,
    });
    lib.linkLibrary(libgit2.artifact("git2"));

    const libgit2_c_src = b.dependency("libgit2_c", .{});
    lib.addIncludePath(libgit2_c_src.path("include"));

    b.installArtifact(lib);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("gitz", lib_mod);
    const exe = b.addExecutable(.{
        .name = "playground",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    const include_pattern = try std.fmt.allocPrint(
        b.allocator,
        "--include-pattern={s}",
        .{b.pathJoin(&.{ b.build_root.path.?, "src" })},
    );
    defer b.allocator.free(include_pattern);
    const cover_cmd = b.addSystemCommand(&.{
        "kcov",
        "--clean",
        include_pattern,
        b.pathJoin(&.{ b.install_path, "cover" }),
    });
    cover_cmd.addArtifactArg(lib_unit_tests);
    const cover_step = b.step("cover", "Generate test coverage report");
    cover_step.dependOn(&cover_cmd.step);
}
