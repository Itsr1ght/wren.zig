const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const Method = @import("method.zig").Method;
const ObjString = @import("string.zig").ObjString;

pub const ObjClass = struct {
    obj: Obj,

    superclass: ?*ObjClass = null,
    num_fields: usize = 0,

    methods: std.StringHashMap(Method),

    name: *ObjString,

    attributes: Value,

    pub fn init(
        allocator: std.mem.Allocator,
        name: *ObjString,
        superclass: ?*ObjClass,
    ) ObjClass {
        return .{
            .obj = .{
                .type = .class,
                .is_dark = false,
            },
            .superclass = superclass,
            .num_fields = 0,
            .methods = .init(allocator),
            .name = name,
            .attributes = undefined,
        };
    }

    pub fn addMethod(
        self: *ObjClass,
        signature: []const u8,
        method: Method,
    ) !void {
        try self.methods.put(signature, method);
    }

    pub fn findMethod(
        self: *const ObjClass,
        signature: []const u8,
    ) ?Method {
        if (self.methods.get(signature)) |method| {
            return method;
        }

        if (self.superclass) |superclass| {
            return superclass.findMethod(signature);
        }

        return null;
    }

    pub fn deinit(
        self: *ObjClass,
    ) void {
        self.methods.deinit();

        // DO NOT deinit/destroy superclass.
        //
        // superclass is only a reference.
        // The VM owns the class objects.
    }
};
