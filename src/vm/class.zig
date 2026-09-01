const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const Method = @import("method.zig").Method;
const ObjString = @import("string.zig").ObjString;

pub const ObjClass = struct {
    obj: Obj,
    superclass: ?*ObjClass,
    num_fields: i32 = 0,
    methods: std.ArrayList(Method),
    name: *ObjString,
    attributes: Value,

    pub fn deinit(self: *ObjClass, allocator: std.mem.Allocator) void {
        self.methods.deinit(allocator);
        if (self.superclass) |cls| cls.deinit(allocator);
    }
};
