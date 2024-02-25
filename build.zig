const std = @import("std");
const builtin = @import("builtin");

const ArrayList = std.ArrayList;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zydis = b.addStaticLibrary(.{
        .name = "zydis",
        .target = target,
        .optimize = optimize,
    });
    zydis.want_lto = false;
    if (optimize == .Debug or optimize == .ReleaseSafe)
        zydis.bundle_compiler_rt = true;

    zydis.linkLibC();
    zydis.linkLibrary(b.dependency("zycore", .{
        .target = target,
        .optimize = optimize,
    }).artifact("zycore"));

    if (target.result.os.tag == .windows) {
        zydis.linkSystemLibrary("ntdll");
        zydis.linkSystemLibrary("kernel32");
        zydis.linkSystemLibrary("advapi32");
    }

    zydis.addIncludePath(.{ .path = "include" });
    zydis.addIncludePath(.{ .path = "src" });
    var zydis_flags = ArrayList([]const u8).init(b.allocator);
    var zydis_sources = ArrayList([]const u8).init(b.allocator);
    defer zydis_flags.deinit();
    defer zydis_sources.deinit();

    try zydis_flags.append("-DZYDIS_STATIC_BUILD=1");
    try zydis_sources.append("src/MetaInfo.c");
    try zydis_sources.append("src/Mnemonic.c");
    try zydis_sources.append("src/Register.c");
    try zydis_sources.append("src/SharedData.c");
    try zydis_sources.append("src/String.c");
    try zydis_sources.append("src/Utils.c");
    try zydis_sources.append("src/Zydis.c");
    try zydis_sources.append("src/Decoder.c");
    try zydis_sources.append("src/DecoderData.c");
    try zydis_sources.append("src/Encoder.c");
    try zydis_sources.append("src/EncoderData.c");
    try zydis_sources.append("src/Formatter.c");
    try zydis_sources.append("src/FormatterBuffer.c");
    try zydis_sources.append("src/FormatterATT.c");
    try zydis_sources.append("src/FormatterBase.c");
    try zydis_sources.append("src/FormatterIntel.c");
    zydis.addCSourceFiles(.{ .files = zydis_sources.items, .flags = zydis_flags.items });

    zydis.installHeadersDirectory("include/Zydis", "Zydis");

    b.installArtifact(zydis);
}
