const std = @import("std");

const Obj = @import("object.zig").Obj;

pub const FnDebug = struct {
    name: []const u8,
    source_lines: std.ArrayList(u8) = .empty,
};

pub const ValueType = enum {
    false,
    null,
    num,
    true,
    undefined,
    obj,
};

pub const Value = struct {
    type: ValueType,
    as: union {
        num: f64,
        obj: Obj,
    },
};

pub const ObjUpValue = struct {
    obj: Obj,
    value: *Value,
    closed: Value,
    next: *ObjUpValue,
};
