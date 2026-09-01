const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const Method = @import("method.zig").Method;
const ObjString = @import("string.zig").ObjString;

pub const ObjClass = struct {
    obj: Obj,
    superclass: ?*ObjClass,
    num_fields: i32 = 0,
    methods: std.StringHashMap(Method),
    name: *ObjString,
    attributes: Value,

    pub fn findMethod(self: *const ObjClass, signature: []const u8) ?Method {
        if (self.methods.get(signature)) |method| {
            return method;
        }
        if (self.superclass) |supercls| {
            return supercls.findMethod(signature);
        }
        return null;
    }

    pub fn addMethod(self: *ObjClass, signature: []const u8, method: Method) !void {
        try self.methods.put(signature, method);
    }

    pub fn deinit(self: *ObjClass) void {
        self.methods.deinit();
        if (self.superclass) |cls| cls.deinit();
    }
};
