const std = @import("std");
const Allocator = std.mem.Allocator;
const color = @import("color.zig");

pub const Indexed1 = Indexed(color.RGBA32F, u1);
pub const Indexed4 = Indexed(color.RGBA32F, u4);
pub const Indexed8 = Indexed(color.RGBA32F, u8);

pub fn Indexed(comptime Col: type, comptime Idx: type) type {
    return struct {
        pub const Error = error{ NotEnoughSlotsInColorPalette, IndexedCorrupted };

        pub const Color = Col;
        pub const Index = Idx;
        const Self = @This();

        palette: []Color,
        indices: []Index,

        pub fn init(pixel_count: usize, allocator: Allocator) !Self {
            var palette = try allocator.alloc(Color, std.math.maxInt(Index) + 1);
            for (palette) |*col| {
                const nan = std.math.nan(f32);
                col.* = Color.init(nan, nan, nan, nan);
            }
            return Self{
                .palette = palette,
                .indices = try allocator.alloc(Index, pixel_count),
            };
        }

        pub fn deinit(self: Self, allocator: Allocator) void {
            allocator.free(self.palette);
            allocator.free(self.indices);
        }

        pub fn isColorInPalette(self: Self, c: Color) bool {
            for (self.palette) |col| {
                if (col.eql(c)) {
                    return true;
                }
            }
            return false;
        }

        pub fn isEmptySlotInPalette(self: Self) bool {
            for (self.palette) |col| {
                if (std.math.isNan(col.r)) {
                    return true;
                }
            }
            return false;
        }

        pub fn at(self: Self, pos: usize) !Color {
            const col = self.palette[self.indices[pos]];
            if (std.math.isNan(col.r)) {
                return Error.IndexedCorrupted;
            }
            return col;
        }

        pub fn set(self: *Self, pos: usize, c: Color) !void {
            var index: Index = loop: for (self.palette, 0..) |col, i| {
                const idx = std.math.cast(Index, i) orelse unreachable;
                if (std.math.isNan(col.r)) {
                    self.palette[idx] = c;
                    break :loop idx;
                } else if (col.eql(c)) {
                    break :loop idx;
                }
            } else {
                return Error.NotEnoughSlotsInColorPalette;
            };

            self.indices[pos] = index;
        }
    };
}

pub const Format = enum {
    indexed1,
    indexed4,
    indexed8,
    rgba32f,
    rgba32,
    bgra32,
    argb32,
    abgr32,
    rgb24,
    bgr24,
    argb4444,
    argb1555,
    rgb565,
    rgb555,
    a2r10g10b10,
    a2b10g10r10,
    grayscale1,
    grayscale4,
    grayscale8,

    const Self = @This();

    fn StorageType(comptime self: Self) type {
        return switch (self) {
            .indexed1 => Indexed1,
            .indexed4 => Indexed4,
            .indexed8 => Indexed8,
            else => []self.ColorType(),
        };
    }

    fn ColorType(comptime self: Self) type {
        return switch (self) {
            .indexed1 => self.StorageType().Color,
            .indexed4 => self.StorageType().Color,
            .indexed8 => self.StorageType().Color,
            .rgba32f => color.RGBA32F,
            .rgba32 => color.RGBA32,
            .bgra32 => color.BGRA32,
            .argb32 => color.ARGB32,
            .abgr32 => color.ABGR32,
            .rgb24 => color.RGB24,
            .bgr24 => color.BGR24,
            .argb4444 => color.ARGB4444,
            .argb1555 => color.ARGB1555,
            .rgb565 => color.RGB565,
            .rgb555 => color.RGB555,
            .a2r10g10b10 => color.A2R10G10B10,
            .a2b10g10r10 => color.A2B10G10R10,
            .grayscale1 => color.Grayscale1,
            .grayscale4 => color.Grayscale4,
            .grayscale8 => color.Grayscale8,
        };
    }

    fn isConversionLossy(comptime self: Self, comptime from: Self) bool {
        comptime return self.ColorType().isConversionLossy(from.ColorType());
    }
};

pub const Storage = union(Format) {
    indexed1: Indexed1,
    indexed4: Indexed4,
    indexed8: Indexed8,
    rgba32f: []color.RGBA32F,
    rgba32: []color.RGBA32,
    bgra32: []color.BGRA32,
    argb32: []color.ARGB32,
    abgr32: []color.ABGR32,
    rgb24: []color.RGB24,
    bgr24: []color.BGR24,
    argb4444: []color.ARGB4444,
    argb1555: []color.ARGB1555,
    rgb565: []color.RGB565,
    rgb555: []color.RGB555,
    a2r10g10b10: []color.A2R10G10B10,
    a2b10g10r10: []color.A2B10G10R10,
    grayscale1: []color.Grayscale1,
    grayscale4: []color.Grayscale4,
    grayscale8: []color.Grayscale8,

    const Self = @This();

    pub fn init(format: Format, pixel_count: usize, allocator: Allocator) !Self {
        return switch (format) {
            .indexed1 => Self{ .indexed1 = try Indexed1.init(pixel_count, allocator) },
            .indexed4 => Self{ .indexed4 = try Indexed4.init(pixel_count, allocator) },
            .indexed8 => Self{ .indexed8 = try Indexed8.init(pixel_count, allocator) },
            .rgba32f => Self{ .rgba32f = try allocator.alloc(Format.ColorType(.rgba32f), pixel_count) },
            .rgba32 => Self{ .rgba32 = try allocator.alloc(Format.ColorType(.rgba32), pixel_count) },
            .bgra32 => Self{ .bgra32 = try allocator.alloc(Format.ColorType(.bgra32), pixel_count) },
            .argb32 => Self{ .argb32 = try allocator.alloc(Format.ColorType(.argb32), pixel_count) },
            .abgr32 => Self{ .abgr32 = try allocator.alloc(Format.ColorType(.abgr32), pixel_count) },
            .rgb24 => Self{ .rgb24 = try allocator.alloc(Format.ColorType(.rgb24), pixel_count) },
            .bgr24 => Self{ .bgr24 = try allocator.alloc(Format.ColorType(.bgr24), pixel_count) },
            .argb4444 => Self{ .argb4444 = try allocator.alloc(Format.ColorType(.argb4444), pixel_count) },
            .argb1555 => Self{ .argb1555 = try allocator.alloc(Format.ColorType(.argb1555), pixel_count) },
            .rgb565 => Self{ .rgb565 = try allocator.alloc(Format.ColorType(.rgb565), pixel_count) },
            .rgb555 => Self{ .rgb555 = try allocator.alloc(Format.ColorType(.rgb555), pixel_count) },
            .a2r10g10b10 => Self{ .a2r10g10b10 = try allocator.alloc(Format.ColorType(.a2r10g10b10), pixel_count) },
            .a2b10g10r10 => Self{ .a2b10g10r10 = try allocator.alloc(Format.ColorType(.a2b10g10r10), pixel_count) },
            .grayscale1 => Self{ .grayscale1 = try allocator.alloc(Format.ColorType(.grayscale1), pixel_count) },
            .grayscale4 => Self{ .grayscale4 = try allocator.alloc(Format.ColorType(.grayscale4), pixel_count) },
            .grayscale8 => Self{ .grayscale8 = try allocator.alloc(Format.ColorType(.grayscale8), pixel_count) },
        };
    }

    /// may be a lossy conversion
    pub fn from(format: Format, from_value: Storage, allocator: Allocator) !Self {
        const pixel_count = from_value.len();
        var self = try init(format, pixel_count, allocator);

        var i: u32 = 0;
        while (i < pixel_count) : (i += 1) {
            switch (from_value) {
                .indexed1 => |data| {
                    const From = Format.ColorType(.indexed1);
                    const from_color = try data.at(i);
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .indexed4 => |data| {
                    const From = Format.ColorType(.indexed4);
                    const from_color = try data.at(i);
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .indexed8 => |data| {
                    const From = Format.ColorType(.indexed8);
                    const from_color = try data.at(i);
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .rgba32f => |data| {
                    const From = Format.ColorType(.rgba32f);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .rgba32 => |data| {
                    const From = Format.ColorType(.rgba32);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .bgra32 => |data| {
                    const From = Format.ColorType(.bgra32);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .argb32 => |data| {
                    const From = Format.ColorType(.argb32);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .abgr32 => |data| {
                    const From = Format.ColorType(.abgr32);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .rgb24 => |data| {
                    const From = Format.ColorType(.rgb24);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .bgr24 => |data| {
                    const From = Format.ColorType(.bgr24);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .argb4444 => |data| {
                    const From = Format.ColorType(.argb4444);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .argb1555 => |data| {
                    const From = Format.ColorType(.argb1555);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .rgb565 => |data| {
                    const From = Format.ColorType(.rgb565);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .rgb555 => |data| {
                    const From = Format.ColorType(.rgb555);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .a2r10g10b10 => |data| {
                    const From = Format.ColorType(.a2r10g10b10);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .a2b10g10r10 => |data| {
                    const From = Format.ColorType(.a2b10g10r10);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .grayscale1 => |data| {
                    const From = Format.ColorType(.grayscale1);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .grayscale4 => |data| {
                    const From = Format.ColorType(.grayscale4);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
                .grayscale8 => |data| {
                    const From = Format.ColorType(.grayscale8);
                    const from_color = data[i];
                    switch (self) {
                        .indexed1 => |*target| try target.set(i, Format.ColorType(.indexed1).from(From, from_color)),
                        .indexed4 => |*target| try target.set(i, Format.ColorType(.indexed4).from(From, from_color)),
                        .indexed8 => |*target| try target.set(i, Format.ColorType(.indexed8).from(From, from_color)),
                        .rgba32f => |target| target[i] = Format.ColorType(.rgba32f).from(From, from_color),
                        .rgba32 => |target| target[i] = Format.ColorType(.rgba32).from(From, from_color),
                        .bgra32 => |target| target[i] = Format.ColorType(.bgra32).from(From, from_color),
                        .argb32 => |target| target[i] = Format.ColorType(.argb32).from(From, from_color),
                        .abgr32 => |target| target[i] = Format.ColorType(.abgr32).from(From, from_color),
                        .rgb24 => |target| target[i] = Format.ColorType(.rgb24).from(From, from_color),
                        .bgr24 => |target| target[i] = Format.ColorType(.bgr24).from(From, from_color),
                        .argb4444 => |target| target[i] = Format.ColorType(.argb4444).from(From, from_color),
                        .argb1555 => |target| target[i] = Format.ColorType(.argb1555).from(From, from_color),
                        .rgb565 => |target| target[i] = Format.ColorType(.rgb565).from(From, from_color),
                        .rgb555 => |target| target[i] = Format.ColorType(.rgb555).from(From, from_color),
                        .a2r10g10b10 => |target| target[i] = Format.ColorType(.a2r10g10b10).from(From, from_color),
                        .a2b10g10r10 => |target| target[i] = Format.ColorType(.a2b10g10r10).from(From, from_color),
                        .grayscale1 => |target| target[i] = Format.ColorType(.grayscale1).from(From, from_color),
                        .grayscale4 => |target| target[i] = Format.ColorType(.grayscale4).from(From, from_color),
                        .grayscale8 => |target| target[i] = Format.ColorType(.grayscale8).from(From, from_color),
                    }
                },
            }
        }

        return self;
    }

    pub fn deinit(self: Self, allocator: Allocator) void {
        switch (self) {
            .indexed1 => |data| data.deinit(allocator),
            .indexed4 => |data| data.deinit(allocator),
            .indexed8 => |data| data.deinit(allocator),
            .rgba32f => |data| allocator.free(data),
            .rgba32 => |data| allocator.free(data),
            .bgra32 => |data| allocator.free(data),
            .argb32 => |data| allocator.free(data),
            .abgr32 => |data| allocator.free(data),
            .rgb24 => |data| allocator.free(data),
            .bgr24 => |data| allocator.free(data),
            .argb4444 => |data| allocator.free(data),
            .argb1555 => |data| allocator.free(data),
            .rgb565 => |data| allocator.free(data),
            .rgb555 => |data| allocator.free(data),
            .a2r10g10b10 => |data| allocator.free(data),
            .a2b10g10r10 => |data| allocator.free(data),
            .grayscale1 => |data| allocator.free(data),
            .grayscale4 => |data| allocator.free(data),
            .grayscale8 => |data| allocator.free(data),
        }
    }

    pub fn len(self: Self) usize {
        return switch (self) {
            .indexed1 => |data| data.indices.len,
            .indexed4 => |data| data.indices.len,
            .indexed8 => |data| data.indices.len,
            .rgba32f => |data| data.len,
            .rgba32 => |data| data.len,
            .bgra32 => |data| data.len,
            .argb32 => |data| data.len,
            .abgr32 => |data| data.len,
            .rgb24 => |data| data.len,
            .bgr24 => |data| data.len,
            .argb4444 => |data| data.len,
            .argb1555 => |data| data.len,
            .rgb565 => |data| data.len,
            .rgb555 => |data| data.len,
            .a2r10g10b10 => |data| data.len,
            .a2b10g10r10 => |data| data.len,
            .grayscale1 => |data| data.len,
            .grayscale4 => |data| data.len,
            .grayscale8 => |data| data.len,
        };
    }

    pub fn bytes(self: Self) []u8 {
        return switch (self) {
            .indexed1 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed4 => |data| std.mem.sliceAsBytes(data.indices),
            .indexed8 => |data| std.mem.sliceAsBytes(data.indices),
            .rgba32f => |data| std.mem.sliceAsBytes(data),
            .rgba32 => |data| std.mem.sliceAsBytes(data),
            .bgra32 => |data| std.mem.sliceAsBytes(data),
            .argb32 => |data| std.mem.sliceAsBytes(data),
            .abgr32 => |data| std.mem.sliceAsBytes(data),
            .rgb24 => |data| std.mem.sliceAsBytes(data),
            .bgr24 => |data| std.mem.sliceAsBytes(data),
            .argb4444 => |data| std.mem.sliceAsBytes(data),
            .argb1555 => |data| std.mem.sliceAsBytes(data),
            .rgb565 => |data| std.mem.sliceAsBytes(data),
            .rgb555 => |data| std.mem.sliceAsBytes(data),
            .a2r10g10b10 => |data| std.mem.sliceAsBytes(data),
            .a2b10g10r10 => |data| std.mem.sliceAsBytes(data),
            .grayscale1 => |data| std.mem.sliceAsBytes(data),
            .grayscale4 => |data| std.mem.sliceAsBytes(data),
            .grayscale8 => |data| std.mem.sliceAsBytes(data),
        };
    }
};
