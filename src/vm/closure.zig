const Obj = @import("object.zig").Obj;
const ObjFn = @import("function.zig").ObjFn;
const ObjUpValue = @import("value.zig").ObjUpValue;

pub const ObjClosure = struct {
    obj: Obj,
    @"fn": ObjFn,
    upvalues: []ObjUpValue,
};
