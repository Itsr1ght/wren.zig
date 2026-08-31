pub const ObjType = enum {
    class,
    closure,
    fiber,
    @"fn",
    foreign,
    instance,
    list,
    map,
    module,
    range,
    string,
    upvalue,
};

pub const Obj = struct {
    type: ObjType,
    is_dark: bool,

    next: ?*Obj = null,
};
