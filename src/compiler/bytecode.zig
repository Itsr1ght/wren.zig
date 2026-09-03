const std = @import("std");
const ObjFn = @import("../vm/function.zig").ObjFn;
const Value = @import("../vm/value.zig").Value;

pub const OpCode = enum(u8) {
    load_constant,
    pop,
    add,
    subtract,
    multiply,
    divide,
    negate,
    get_local,
    set_local,
    call,
    @"return",
};

pub fn emitOp(func: *ObjFn, allocator: std.mem.Alignment, op: OpCode) !void {
    try func.code.append(allocator, @intFromEnum(op));
}

pub fn emitBytes(func: *ObjFn, allocator: std.mem.Alignment, byte: u8) !void {
    try func.code.append(allocator, byte);
}

pub fn emitConstant(func: *ObjFn, allocator: std.mem.Allocator, value: Value) !u8 {
    try func.constants.append(allocator, value);
    const index: u8 = @intCast(func.constants.items.len - 1);
    try emitOp(func, allocator, .load_constant);
    try emitBytes(func, allocator, index);
}
