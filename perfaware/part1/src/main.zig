const std = @import("std");
const fs = std.fs;

const Masks = struct {
    const OPERAND = 0b11111100;
    const D = 0b00000010;
    const W = 0b00000001;
    const MOD = 0b11000000;
    const REG = 0b00111000;
    const RM = 0b00000111;
};

pub fn read_file(allocator: std.mem.Allocator, binary_file_path: [:0]u8) ![]u8 {
    const bytes = try fs.cwd().readFileAlloc(allocator, binary_file_path, 1024 * 1024);
    return bytes;
}

pub fn decode_register(byte: u8, w: bool) *const [2:0]u8 {
    const reg = switch (byte) {
        0b00000000             => if (w) "ax" else "al",
        0b00001000, 0b00000001 => if (w) "cx" else "cl",
        0b00010000, 0b00000010 => if (w) "dx" else "dl",
        0b00011000, 0b00000011 => if (w) "bx" else "bl",
        0b00100000, 0b00000100 => if (w) "sp" else "ah",
        0b00101000, 0b00000101 => if (w) "bp" else "ch",
        0b00110000, 0b00000110 => if (w) "si" else "dh",
        0b00111000, 0b00000111 => if (w) "di" else "bh",
        else => unreachable,
    };

    return reg;
}

pub fn decode(bytes: []const u8, stdout_file: std.fs.File.Writer) !void {
    const opcode = switch (bytes[0] & Masks.OPERAND) {
        0b10001000 => "mov",
        else => unreachable,
    };

    // d == 1 -> REG is destination operand
    // d == 0 -> REG is source operand
    const d = if ((bytes[0] & Masks.D) == 0b00000010) true else false;

    // w == 1 -> word(16-bit) data;
    // w == 0 -> byte(8-bit) data;
    const w = if ((bytes[0] & Masks.W) == 0b00000001) true else false;

    // mod == 11 -> register-to-register mode, only one allowed. Crash otherwise.
    const mod = bytes[1] & Masks.MOD;
    if (mod != 0b11000000) {
        std.debug.print("MOD must be '0b11000000', found {d}", .{mod});
        unreachable;
    }

    const reg = decode_register(bytes[1] & Masks.REG, w);
    const rm = decode_register(bytes[1] & Masks.RM, w);

    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    if (d) {
        try stdout.print("{s} {s}, {s} \n", .{ opcode, reg, rm });
    } else {
        try stdout.print("{s} {s}, {s} \n", .{ opcode, rm, reg });
    }

    try bw.flush();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const stdout_file = std.io.getStdOut().writer();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    
    if (args.len != 2) {
        std.debug.print("Required argument: path to Binary File\n", .{});
        unreachable;
    }
    const binary_file_path = args[1];
    std.debug.print("{s}\n", .{binary_file_path});

    // Read byte content from input file
    const bytes = try read_file(allocator, binary_file_path);

    // Loop over binary instructions, decode and flush to stdout
    var i: usize = 0;
    while (i < bytes.len) : (i += 2) {
        const instruction: []u8 = bytes[i..i+2]; 
        try decode(instruction, stdout_file);
    }
}
