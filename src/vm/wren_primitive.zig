const util = @import("wren_utils.zig");
const value = @import("wren_value.zig");

const WrenVm = @import("../lib.zig").WrenVM;
const ObjClass = @import("wren_value.zig").ObjClass;
const Method = @import("wren_value.zig").Method;

pub const Primitive = *const fn (vm: WrenVm) void;

pub fn bindPrimitive(
    vm: *WrenVm,
    obj_class: *ObjClass,
    name: []const u8,
    function: Primitive,
) !void {
    const symbol = try vm.method_names.ensure(vm.allocator, name);
    const method = Method{ .type = .primitive, .implementation = .{
        .primitive = function,
    } };

    try value.bindMethod(obj_class, symbol, method);
}
