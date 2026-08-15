const WrenVm = @import("../lib.zig").WrenVM;

pub const Primitive = *const fn (vm: WrenVm) void;
