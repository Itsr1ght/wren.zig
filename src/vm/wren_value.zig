const std = @import("std");
const primitive = @import("wren_primitive.zig");
const function = @import("wren_function.zig");
const foriegn = @import("wren_foreign.zig");
const utils = @import("wren_utils.zig");

const WrenVM = @import("../lib.zig").WrenVM;

const SymbolTable = @import("wren_function.zig").SymbolTable;

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
    is_dark: bool,
};

pub const ObjModule = struct {
    obj: Obj,
    variables: std.ArrayList(Value),
    variable_names: SymbolTable,
    name: []const u8,
};

pub const ObjClass = struct {
    obj: Obj,
    superclass: ObjClass,
    num_field: i32,
    methods: std.ArrayList(Method) = .empty,
    name: []const u8,
    attribute: Value,
};

pub const Value = union(enum) {
    nil,
    boolean: bool,
    number: f64,
    object: *Obj,
};

pub const FnDebug = struct {
    name: []const u8,
    source_lines: std.ArrayList(i32) = .empty,
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
    code: std.ArrayList(u8) = .empty,
    constants: std.ArrayList(Value) = .empty,
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
    Obj_up_value: []ObjUpValue,
};

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

pub fn bindMethod(allocator: *std.mem.Allocator, obj_class: *ObjClass, symbol: i32, method: Method) !void {
    if (symbol >= obj_class.methods.items.len) {
        utils.methodBufferFill(allocator, &obj_class.methods, symbol);
    }
    obj_class.methods.items[symbol] = method;
}
