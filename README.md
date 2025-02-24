# gitz

**NOTE:** Please read disclaimer below.

Zig 0.14.0-dev wrapper for libgit2.

The goal is to have a nice and ergonomic wrapper similar to `git2` in Rust.

## Disclaimer

I'm building this library to learn more about Zig and C interop, don't expect it
to be good, or bulletproof, or production-ready, or actively supported. This is
not even alpha quality at this point.

This repository is a work-in-progress and very few features are currently
implemented. I am mainly using `gitz` in another project and mostly implements
features as I come across them in libgit2's reference, or when I actually need
them.

There are no tests in the code and organization is complete garbage. I am aware
the code is shit, but please do not hesitate to tell me how and why as I am
eager to learn more Zig!

The library currently uses my personal fork of [allyourcodebase/libgit2](https://github.com/allyourcodebase/libgit2)
since it has not yet been updated to work with Zig 0.14.

With this out of the way, let's get into how you can actually use this library.

## Usage

Add the package to your `build.zig.zon`:
```
zig fetch --save git+https://github.com/blurrycat/gitz
```

Then you can add the library as a dependency in your `build.zig`:
```zig
const gitz_dep = b.dependency("gitz", .{
    .target = target,
    .optimize = optimize,
});
your_module.addImport("gitz", gitz_dep.module("gitz"));
your_compile_step.linkLibrary(gitz_dep.artifact("gitz"));
```

You can then import `gitz` in your code:
```zig
const gitz = @import("gitz");
```

## Acknowledgements

Thanks to the `git2` crate authors for their work, the crate is a really nice
reference to have and much of `gitz` is currently inspired by the crate.
