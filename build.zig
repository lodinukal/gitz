const std = @import("std");
pub const libgit2 = @import("libgit2");

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
    });

    const default_tls_backend: libgit2.TlsBackend = if (target.result.os.tag == .macos) .securetransport else .mbedtls;
    const tls_backend = b.option(
        libgit2.TlsBackend,
        "tls-backend",
        "Choose Unix TLS/SSL backend",
    ) orelse default_tls_backend;
    const enable_ssh = b.option(bool, "enable-ssh", "Enable SSH support") orelse false;
    const libgit2_dep = b.dependency("libgit2", .{
        .target = target,
        .optimize = optimize,
        .@"enable-ssh" = enable_ssh,
        .@"tls-backend" = tls_backend,
    });
    lib.linkLibrary(libgit2_dep.artifact("git2"));

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
