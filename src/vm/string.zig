const Obj = @import("object.zig").Obj;

pub const ObjString = struct {
    obj: Obj,
    char: []const u8,
    length: usize,
};
