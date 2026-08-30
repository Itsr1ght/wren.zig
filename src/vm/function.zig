const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const FnDebug = @import("value.zig").FnDebug;
const ObjModule = @import("module.zig").ObjModule;

pub const ObjFn = struct {
    obj: Obj,

    code: std.ArrayList(u8) = .empty,
    constants: std.ArrayList(Value) = .empty,

    module: ?*ObjModule = null,
    max_slots: usize = 0,
    num_upvalues: usize = 0,
    arity: usize = 0,

    debug: ?*FnDebug = null,
};
