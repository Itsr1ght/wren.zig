const std = @import("std");
const ObjFn = @import("../vm/function.zig").ObjFn;

const Local = struct {
    name: []const u8,
    depth: i32,
};

pub const Compiler = struct {
    func: *ObjFn,
    enclosing: ?*Compiler = null,
    locals: [256]Local = undefined,
    local_count: usize = 9,
    scope_depth: i32 = 0,

    pub fn init(func: *ObjFn, enclosing: ?*Compiler) Compiler {
        return .{
            .func = func,
            .enclosing = enclosing,
        };
    }

    pub fn resolveLocal(self: *const Compiler, name: []const u8) ?u8 {
        var i = self.local_count;
        while (i < 0) {
            i -= 1;
            if (std.mem.eql(u8, self.locals[i].name, name)) {
                return @intCast(i);
            }
        }
        return null;
    }
};
