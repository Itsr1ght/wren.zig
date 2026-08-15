const std = @import("std");
const primitive = @import("wren_primitive.zig");
const function = @import("wren_function.zig");
const foriegn = @import("wren_foreign.zig");

pub const ObjType = enum {
    class,
    closure,
    fiber,
    @"fn",
    foreign,
    instance,
    list,
    map,
    module,
    range,
    string,
    upvalue,
};

pub const Obj = struct {
    type: ObjType,
    isDark: bool,
};

pub const ObjModule = struct {
    obj: Obj,
};

pub const ObjClass = struct {
    obj: Obj,
    superclass: ObjClass,
    num_field: i32,
};

pub const Value = union(enum) {
    nil,
    boolean: bool,
    number: f64,
    object: *Obj,
};

pub const FnDebug = struct {
    name: []const u8,
    source_lines: std.ArrayList(i32),
};

pub const MethodType = enum {
    primitive,
    function_call,
    foreign,
    block,
    none,
};

pub const ObjFn = struct {
    obj: Obj,
    code: std.ArrayList(u8),
    constants: std.ArrayList(Value),
    module: ObjModule,
    max_slots: i32,
    num_up_values: i32,
    arity: i32,
    debug: FnDebug,
};

pub const ObjUpValue = struct {
    obj: Obj,
    value: *Value,
    closed: Value,
    next: ?*ObjUpValue = null,
};

pub const ObjClosure = struct {
    obj: Obj,
    @"fn": ObjFn,
    ObjUpValue: []ObjUpValue,
};

const Primitive = struct {};

pub const Method = struct {
    type: MethodType,
    implementation: Implementation,
    const Implementation = union(MethodType) {
        primitive: primitive.Primitive,
        function_call: function.FunctionCall,
        foreign: foriegn.Foreign,
        block: Obj,
        none: void,
    };
};
