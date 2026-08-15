const WrenVM = @import("../lib.zig").WrenVM;

pub const Foreign = *const fn (vm: *WrenVM) void;
