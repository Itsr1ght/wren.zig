const WrenVm = @import("../lib.zig").WrenVM;
const ObjClass = @import("wren_value.zig").ObjClass;

pub const Primitive = *const fn (vm: WrenVm) void;

pub fn bindPrimitive(
    obj_class: ObjClass,
    name: []const u8,
    function: []const u8,
) void {
    _ = obj_class;
    _ = name;
    _ = function;
}
