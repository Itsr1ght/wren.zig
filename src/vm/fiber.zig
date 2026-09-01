const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const ObjClosure = @import("closure.zig").ObjClosure;

pub const CallFrame = struct {
    closure: *ObjClosure,
    ip: usize,
    stack_start: usize,
};

pub const ObjFiber = struct {
    obj: Obj,

    stack: []Value,
    stack_top: usize,

    frames: []CallFrame,
    frame_count: usize,

    pub fn init(allocator: std.mem.Allocator) !*ObjFiber {
        const fiber = try allocator.create(ObjFiber);

        const stack = try allocator.create(Value, 256);
        errdefer allocator.free(stack);

        const frames = try allocator.alloc(CallFrame, 64);
        errdefer allocator.free(frames);

        fiber.* = .{
            .obj = .{
                .type = .fiber,
                .is_dark = false,
            },
            .stack = stack,
            .stack_top = 0,
            .frames = frames,
            .frame_count = 0,
        };
        return fiber;
    }

    pub fn push(self: *ObjFiber, value: Value) void {
        self.stack[self.stack_top] = value;
        self.stack_top += 1;
    }

    pub fn pop(self: *ObjFiber) Value {
        self.stack_top -= 1;
        return self.stack[self.stack_top];
    }

    pub fn peek(self: *ObjFiber, distance: usize) Value {
        return self.stack[self.stack_top - 1 - distance];
    }

    pub fn pushFrame(self: *ObjFiber, frame: CallFrame) void {
        self.frames[self.frame_count] = frame;
        self.frame_count += 1;
    }

    pub fn popFrame(self: *ObjFiber) CallFrame {
        self.frame_count -= 1;
        return self.frames[self.frame_count];
    }

    pub fn currentFrame(self: *ObjFiber) *CallFrame {
        return &self.frames[self.frame_count - 1];
    }

    pub fn deinit(self: *ObjFiber, allocator: std.mem.Allocator) void {
        allocator.free(self.stack);
        allocator.free(self.frames);
        allocator.destroy(self);
    }
};
