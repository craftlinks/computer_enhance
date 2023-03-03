// TODO: read binary file name from command line input

// TODO: SIMPLIFY!! interpretation changes with w,  d and MOD... so start from there?
    // TODO: handle MOD != 11 (should abort and report we don't support that) 
    // Don't create enums when simple strings will do...
// TODO: hande multiple instructions!

const std = @import("std");
const fs = std.fs;

const FILE_NAME = "listing_0037_single_register_mov";

const one: u1 = 0b1;
const zero: u1 = 0b0;

const Masks = struct {
    const OPERAND = 0b11111100;
    const D = 0b00000010;
    const W = 0b00000001;
    const MOD = 0b11000000;
    const REG = 0b00111000;
    const RM = 0b00000111;
};

const Opcode = enum(u6) { mov = 0b100010, undefined };

const Mod = enum(u2) {
    m00 = 0b00,
    m01 = 0b01,
    m10 = 0b10,
    m11 = 0b11,
};

const Reg = enum(u3) {
    b000 = 0b000,
    b001 = 0b001,
    b010 = 0b010,
    b011 = 0b011,
    b100 = 0b100,
    b101 = 0b101,
    b110 = 0b110,
    b111 = 0b111,
};

const Register = enum {
    ax,
    cx,
    dx,
    bx,
    sp,
    bp,
    si,
    di,
    al,
    cl,
    dl,
    bl,
    ah,
    ch,
    dh,
    bh,
};

const RM = enum(u3) { b000 = 0b000, b001 = 0b001, b010 = 0b010, b011 = 0b011, b100 = 0b100, b101 = 0b101, b110 = 0b110, b111 = 0b111 };

const Instruction = struct {
    opcode: Opcode,
    d: u1,
    w: u1,
    mod: Mod,
    reg: Reg,
    rm: RM,

    pub fn debug_print(self: Instruction) void {
        std.debug.print("op: {s}, ", .{@tagName(self.opcode)});
        std.debug.print("d: {d}, ", .{self.d});
        std.debug.print("w: {d}, ", .{self.w});
        std.debug.print("mod: {s}, ", .{@tagName(self.mod)});
        std.debug.print("reg: {s}, ", .{@tagName(self.reg)});
        std.debug.print("rm: {s}, \n\n", .{@tagName(self.rm)});
    }
};

pub fn read_file(allocator: std.mem.Allocator) ![]u8 {
    const bytes = try fs.cwd().readFileAlloc(allocator, FILE_NAME, 1024 * 1024);

    std.debug.print("File Contents: {b} \n", .{bytes});

    return bytes;
}

pub fn decode(bytes: []const u8) !Instruction {
    const opcode = switch (bytes[0] & Masks.OPERAND) {
        0b10001000 => Opcode.mov,
        else => Opcode.undefined,
    };

    const d = if ((bytes[0] & Masks.D) == 0b00000010) one else zero;
    const w = if ((bytes[0] & Masks.W) == 0b00000001) one else zero;
    const mod = switch (bytes[1] & Masks.MOD) {
        0b00000000 => Mod.m00,
        0b01000000 => Mod.m01,
        0b10000000 => Mod.m10,
        0b11000000 => Mod.m11,
        else => unreachable,
    };

    const reg = switch (bytes[1] & Masks.REG) {
        0b00000000 => Reg.b000,
        0b00001000 => Reg.b001,
        0b00010000 => Reg.b010,
        0b00011000 => Reg.b011,
        0b00100000 => Reg.b100,
        0b00101000 => Reg.b101,
        0b00110000 => Reg.b110,
        0b00111000 => Reg.b111,
        else => unreachable,
    };

    const rm = switch (bytes[1] & Masks.RM) {
        0b00000000 => RM.b000,
        0b00000001 => RM.b001,
        0b00000010 => RM.b010,
        0b00000011 => RM.b011,
        0b00000100 => RM.b100,
        0b00000101 => RM.b101,
        0b00000110 => RM.b110,
        0b00000111 => RM.b111,
        else => unreachable,
    };

    const instruction: Instruction = .{
        .opcode = opcode,
        .d = d,
        .w = w,
        .mod = mod,
        .reg = reg,
        .rm = rm,
    };

    return instruction;
}

pub fn output(instruction: Instruction) !void {
    instruction.debug_print();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const opcode = @tagName(instruction.opcode);

    const reg = switch (instruction.reg) {
        Reg.b000 => if (instruction.w == 0b1) Register.AX else Register.AL,
        Reg.b001 => if (instruction.w == 0b1) Register.CX else Register.CL,
        Reg.b010 => if (instruction.w == 0b1) Register.DX else Register.DL,
        Reg.b011 => if (instruction.w == 0b1) Register.BX else Register.BL,
        Reg.b100 => if (instruction.w == 0b1) Register.SP else Register.AH,
        Reg.b101 => if (instruction.w == 0b1) Register.BP else Register.CH,
        Reg.b110 => if (instruction.w == 0b1) Register.SI else Register.DH,
        Reg.b111 => if (instruction.w == 0b1) Register.DI else Register.BH,
    };

    const rm = switch (instruction.rm) {
        RM.b000 => if (instruction.w == 0b1) Register.AX else Register.AL,
        RM.b001 => if (instruction.w == 0b1) Register.CX else Register.CL,
        RM.b010 => if (instruction.w == 0b1) Register.DX else Register.DL,
        RM.b011 => if (instruction.w == 0b1) Register.BX else Register.BL,
        RM.b100 => if (instruction.w == 0b1) Register.SP else Register.AH,
        RM.b101 => if (instruction.w == 0b1) Register.BP else Register.CH,
        RM.b110 => if (instruction.w == 0b1) Register.SI else Register.DH,
        RM.b111 => if (instruction.w == 0b1) Register.DI else Register.BH,
    };

    if (instruction.d == 0b1) {
        try stdout.print("{s} {s} {s}", .{ opcode, @tagName(reg), @tagName(rm) });
    } else {
        try stdout.print("{s} {s} {s}", .{ opcode, @tagName(rm), @tagName(reg) });
    }

    try bw.flush(); // don't forget to flush!
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Read byte content from input file
    const bytes = try read_file(allocator);

    // Decode the bytes
    const instruction = try decode(bytes);

    // push instructions to stdout
    try output(instruction);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
