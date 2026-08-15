const std = @import("std");
const Value = @import("vm/wren_value.zig").Value;
const WrenHandle = @import("vm/wren_core.zig").WrenHandle;

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

const WrenForeignMethodFn = *const fn (vm: *WrenVM) void;

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

const WrenForeignClassMethods = struct {
    allocate: WrenForeignMethodFn,
    finalize: *const fn (data: *anyopaque) void,
};

pub const Configuration = struct {
    realAllocFn: ?*const fn (memory: *anyopaque, new_size: usize, user_data: *anyopaque) ?*anyopaque = null,
    resolveModuleFn: ?*const fn (vm: *WrenVM, importer: []const u8, name: []const u8) []const u8 = null,
    loadModuleFn: ?*const fn (vm: *WrenVM, name: []const u8) LoadModuleResult = null,
    bindForeignMethodFn: ?*const fn (
        vm: *WrenVM,
        module: []const u8,
        className: []const u8,
        is_static: bool,
        signature: []const u8,
    ) WrenForeignMethodFn = null,
    bindForeignClassFn: ?*const fn (
        vm: *WrenVM,
        module: []const u8,
        className: []const u8,
    ) WrenForeignClassMethods = null,
    WriteFn: ?*const fn (vm: *WrenVM, text: []const u8) void = null,
    ErrorFn: ?*const fn (
        vm: *WrenVM,
        type: ErrorType,
        module: []const u8,
        line: i32,
        message: []const u8,
    ) void = null,
    initialHeapSize: usize = 1024 * 1024 * 10,
    minHeapSize: usize = 1024 * 1024,
    heapGrowthPercent: u32 = 50,
    user_data: ?*anyopaque = null,

    pub fn init(user_data: ?*anyopaque) Configuration {
        return .{
            .user_data = user_data,
        };
    }
};

pub const LoadModuleResult = struct {
    source: []const u8,
    onComplete: null,
    userData: ?*anyopaque = null,
};

pub fn getVersionNumber() i32 {
    return VERSION_NUMBER;
}

pub fn initConfiguration(configuration: *Configuration) void {
    _ = configuration;
}

pub const newVm = WrenVM.init;

pub const WrenVM = struct {
    configuration: *Configuration,

    pub fn init(configuration: *Configuration) WrenVM {
        return .{
            .configuration = configuration,
        };
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
