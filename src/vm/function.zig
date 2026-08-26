const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const FnDebug = @import("value.zig").FnDebug;
const ObjModule = @import("module.zig").ObjModule;

pub const ObjFn = struct {
    obj: Obj,
    code: std.ArrayList(u8) = .empty,
    constants: std.ArrayList(Value) = .empty,
    module: ObjModule,
    max_slots: i32,
    num_upvalues: i32,
    arity: i32,
    debug: FnDebug,
};
