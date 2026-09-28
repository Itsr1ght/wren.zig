const std = @import("std");

const Runtime = @import("Runtime.zig");
pub const ValueType = enum { num, str, bool };

pub const Value = union(ValueType) {
    num: f64,
    str: []const u8,
    bool: bool,

    pub fn valuesEqual(a: Value, b: Value) bool {
        if (@as(ValueType, a) != @as(ValueType, b)) return false;
        return switch (a) {
            .num => a.num == b.num,
            .bool => a.bool == b.bool,
            .str => std.mem.eql(u8, a.str, b.str),
        };
    }

    pub fn addValues(runtime: *Runtime, a: Value, b: Value) !Value {
        if (@as(ValueType, a) != @as(ValueType, b)) return error.TypeMismatch;
        return switch (a) {
            .num => .{ .num = a.num + b.num },
            .bool => error.TypeMismatch,
            .str => .{
                .str = try runtime.track(try std.mem.concat(
                    runtime.allocator,
                    u8,
                    &.{ a.str, b.str },
                )),
            },
        };
    }

    pub fn subValues(a: Value, b: Value) !Value {
        if (@as(ValueType, a) != @as(ValueType, b)) return error.TypeMismatch;
        return switch (a) {
            .num => .{ .num = a.num - b.num },
            .bool, .str => error.TypeMismatch,
        };
    }

    pub fn multiplyValues(a: Value, b: Value) !Value {
        if (@as(ValueType, a) != @as(ValueType, b)) return error.TypeMismatch;
        return switch (a) {
            .num => .{ .num = a.num * b.num },
            .bool, .str => error.TypeMismatch,
        };
    }

    pub fn divideValues(a: Value, b: Value) !Value {
        if (@as(ValueType, a) != @as(ValueType, b)) return error.TypeMismatch;
        return switch (a) {
            .num => .{ .num = a.num / b.num },
            .bool, .str => error.TypeMismatch,
        };
    }
};
