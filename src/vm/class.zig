const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const Method = @import("method.zig").Method;
const ObjString = @import("string.zig").ObjString;

pub const ObjClass = struct {
    obj: Obj,
    superclass: *ObjClass,
    num_fields: i32,
    methods: std.ArrayList(Method),
    name: *ObjString,
    attributes: Value,
};
