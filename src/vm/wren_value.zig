const ObjType = enum {
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

const Obj = struct {
    type: ObjType,
    isDark: bool,
};

const ObjModule = struct {
    obj: Obj,
};

const ObjClass = struct {
    obj: Obj,
    superclass: ObjClass,
    num_field: i32,
};
