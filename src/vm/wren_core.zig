const Value = @import("wren_value.zig").Value;
const WrenVM = @import("../lib.zig").WrenVM;

pub const WrenHandle = struct {
    value: Value,
    previous: *WrenHandle,
    next: *WrenHandle,
};

pub fn wrenInitializeCore(vm: *WrenVM) void {
    const core_module = vm.newModule("");
    _ = core_module;
}
