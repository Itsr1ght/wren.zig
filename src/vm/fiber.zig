const std = @import("std");

const Obj = @import("object.zig").Obj;
const Value = @import("value.zig").Value;
const ObjClosure = @import("closure.zig").ObjClosure;

pub const STACK_CAPACITY = 256;
pub const FRAME_CAPACITY = 64;

pub const CallFrame = struct {
    closure: *ObjClosure,
    ip: usize = 0,
    stack_start: usize = 0,
};

pub const ObjFiber = struct {
    obj: Obj,

    stack: []Value,
    stack_top: usize = 0,

    frames: []CallFrame,
    frame_count: usize = 0,

    pub fn init(allocator: std.mem.Allocator) !*ObjFiber {
        const fiber = try allocator.create(ObjFiber);

        const stack = try allocator.alloc(Value, STACK_CAPACITY);
        errdefer allocator.free(stack);

        const frames = try allocator.alloc(CallFrame, FRAME_CAPACITY);
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

    pub fn push(
        self: *ObjFiber,
        value: Value,
    ) !void {
        if (self.stack_top >= self.stack.len) {
            return error.StackOverflow;
        }

        self.stack[self.stack_top] = value;
        self.stack_top += 1;
    }

    pub fn pop(
        self: *ObjFiber,
    ) !Value {
        if (self.stack_top == 0) {
            return error.StackUnderflow;
        }

        self.stack_top -= 1;
        return self.stack[self.stack_top];
    }

    pub fn peek(
        self: *const ObjFiber,
        distance: usize,
    ) !Value {
        if (distance >= self.stack_top) {
            return error.StackUnderflow;
        }

        return self.stack[self.stack_top - 1 - distance];
    }

    pub fn pushFrame(
        self: *ObjFiber,
        frame: CallFrame,
    ) !void {
        if (self.frame_count >= self.frames.len) {
            return error.CallStackOverflow;
        }

        self.frames[self.frame_count] = frame;
        self.frame_count += 1;
    }

    pub fn popFrame(
        self: *ObjFiber,
    ) !CallFrame {
        if (self.frame_count == 0) {
            return error.CallStackUnderflow;
        }

        self.frame_count -= 1;
        return self.frames[self.frame_count];
    }

    pub fn currentFrame(
        self: *ObjFiber,
    ) !*CallFrame {
        if (self.frame_count == 0) {
            return error.NoCallFrame;
        }

        return &self.frames[self.frame_count - 1];
    }

    pub fn deinit(
        self: *ObjFiber,
        allocator: std.mem.Allocator,
    ) void {
        allocator.free(self.stack);
        allocator.free(self.frames);
        allocator.destroy(self);
    }
};
