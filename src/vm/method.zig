pub const WrenVM = @import("vm.zig");

pub const Primitive = *const fn (vm: *WrenVM) void;
pub const Foreign = *const fn (vm: *WrenVM) void;
pub const Closure = @import("closure.zig").ObjClosure;

pub const Method = union(enum) {
    primitive: Primitive,
    foreign: Foreign,
    closure: Closure,
};
