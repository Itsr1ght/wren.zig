const Value = @import("wren_value.zig").Value;

pub const WrenHandle = struct {
    value: Value,
    previous: *WrenHandle,
    next: *WrenHandle,
};
