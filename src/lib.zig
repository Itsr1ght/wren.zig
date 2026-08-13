const std = @import("std");

pub const VERSION_MAJOR = 0;
pub const VERSION_MINOR = 4;
pub const VERSION_PATCH = 0;

pub const VERSION_STRING = std.fmt.comptimePrint("{}.{}.{}", .{
    VERSION_MAJOR,
    VERSION_MINOR,
    VERSION_PATCH,
});

pub const VERSION_NUMBER: comptime_int =
    VERSION_MAJOR * 1_000_000 +
    VERSION_MINOR * 1_000 +
    VERSION_PATCH;

pub const InterpretResult = enum {
    success,
    compile_error,
    runtime_error,
};

pub const ErrorType = enum {
    compile,
    runtime,
    stack_trace,
};

pub const Type = enum {
    bool,
    num,
    foreign,
    list,
    map,
    null,
    string,
};

pub const Configuration = struct {
    realAllocFn: i32 = 0,
    resolveModuleFn: i32 = 0,
    loadModuleFn: i32 = 0,
    bindForeignMethodFn: i32 = 0,
    bindForeignClassFn: i32 = 0,
    WriteFn: i32 = 0,
    ErrorFn: i32 = 0,
    initialHeapSize: usize = 0,
    minHeapSize: usize = 0,
    heapGrowthPercent: u32 = 0,
    userData: ?*anyopaque = null,
};

pub const ModuleResult = struct {
    source: []const u8,
    onComplete: null,
    userData: ?*anyopaque = null,
};

const WrenHandle = struct {};

pub fn getVersionNumber() i32 {
    return VERSION_NUMBER;
}

pub fn initConfiguration(configuration: *Configuration) void {
    _ = configuration;
}

pub const newVm = WrenVM.init;

pub const WrenVM = struct {
    pub fn init(configuration: *Configuration) WrenVM {
        _ = configuration;
        return .{};
    }

    pub fn collectGarbage(self: *WrenVM) void {
        _ = self;
    }

    pub fn interpret(self: *WrenVM, module: []const u8, source: []const u8) InterpretResult {
        _ = self;
        _ = module;
        _ = source;
    }

    pub fn makeCallHandle(self: *WrenVM, signature: []const u8) WrenHandle {
        _ = self;
        _ = signature;
        return .{};
    }

    pub fn call(self: *WrenVM, method: WrenHandle) InterpretResult {
        _ = self;
        _ = method;
        return .success;
    }

    pub fn getSlotCount(self: *WrenVM) i32 {
        _ = self;
        return 0;
    }

    pub fn ensureSlots(self: *WrenVM) void {
        _ = self;
        return;
    }

    pub fn getSlotType(self: *WrenVM, slot: i32) Type {
        _ = self;
        _ = slot;
    }

    pub fn getSlotBool(self: *WrenVM, slot: i32) bool {
        _ = self;
        _ = slot;
    }

    pub fn getSlotBytes(self: *WrenVM, slot: i32, length: *i32) []const u8 {
        _ = self;
        _ = slot;
        _ = length;
        return "";
    }

    pub fn getSlotDouble(self: *WrenVM, slot: i32) f64 {
        _ = self;
        _ = slot;
        return 0.0;
    }

    pub fn getSlotForeign(self: *WrenVM, slot: i32) ?*anyopaque {
        _ = self;
        _ = slot;
        return null;
    }

    pub fn getSlotString(self: *WrenVM, slot: i32) []const u8 {
        _ = self;
        _ = slot;
        return "";
    }

    pub fn getSlotHandle(self: *WrenVM, slot: i32) *WrenHandle {
        _ = self;
        _ = slot;
        return .{};
    }

    pub fn setSlotBool(self: *WrenVM, slot: i32, value: bool) void {
        _ = self;
        _ = slot;
        _ = value;
    }

    pub fn deinit(self: *WrenVM) void {
        _ = self;
    }
};
