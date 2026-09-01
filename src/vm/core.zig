const system = @import("system.zig");

const WrenVM = @import("vm.zig").WrenVM;

pub fn initialize(vm: *WrenVM) !void {
    const system_class = try vm.createClass(try vm.copyString("System"), null);
    try system_class.addMethod("print", .{ .primitive = system.print });
}
