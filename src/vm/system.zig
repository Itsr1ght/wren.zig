const WrenVM = @import("vm.zig").WrenVM;

pub fn print(vm: *WrenVM) void {
    const text = vm.getArgument(0);
    vm.config.write(vm, text);
}
