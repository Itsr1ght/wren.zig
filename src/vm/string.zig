const std = @import("std");

const Obj = @import("object.zig").Obj;

pub const ObjString = struct {
    obj: Obj,
    char: []u8,

    pub fn init(allocator: std.mem.Allocator, data: []const u8) !*ObjString {
        const obj_string = try allocator.create(ObjString);
        obj_string.* = .{
            .obj = .{
                .type = .string,
                .is_dark = false,
            },
            .char = try allocator.dupe(u8, data),
        };

        return obj_string;
    }

    pub fn deinit(self: *ObjString, allocator: std.mem.Allocator) void {
        allocator.free(self.char);
        allocator.destroy(self);
    }
};
