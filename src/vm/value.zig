const std = @import("std");

const Obj = @import("object.zig").Obj;

pub const FnDebug = struct {
    name: []const u8,
    source_lines: std.ArrayList(u8) = .empty,
};

pub const ValueType = enum {
    false,
    nil,
    num,
    true,
    undefined,
    obj,
};

pub const Value = struct {
    type: ValueType,
    as: union {
        boolean: bool,
        num: f64,
        obj: Obj,
        nil: void,
    },
};

pub const ObjUpValue = struct {
    obj: Obj,
    value: *Value,
    closed: Value,
    next: *ObjUpValue,
};
