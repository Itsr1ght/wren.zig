pub const ValueType = enum { num, str };

pub const Value = union(ValueType) {
    num: f64,
    str: []const u8,
};
