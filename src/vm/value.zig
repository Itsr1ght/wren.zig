const std = @import("std");

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
};
