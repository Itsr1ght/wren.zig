const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const ObjString = @import("string.zig").ObjString;
const SymbolTable = @import("../compiler/symbol_table.zig").SymbolTable;

pub const ObjModule = struct {
    obj: Obj,
    variables: std.ArrayList(Value) = .empty,
    variable_names: SymbolTable,
    name: ObjString,
};
