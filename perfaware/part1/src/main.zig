// TODO: read binary file name from command line input
// TODO: hande multiple instructions!

const std = @import("std");
const fs = std.fs;

const FILE_NAME = "listing_0037_single_register_mov";

const Masks = struct {
    const OPERAND = 0b11111100;
    const D = 0b00000010;
    const W = 0b00000001;
    const MOD = 0b11000000;
    const REG = 0b00111000;
    const RM = 0b00000111;
};

pub fn read_file(allocator: std.mem.Allocator) ![]u8 {
    const bytes = try fs.cwd().readFileAlloc(allocator, FILE_NAME, 1024 * 1024);

    std.debug.print("File Contents: {b} \n", .{bytes});

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
        try stdout.print("{s} {s} {s}", .{ opcode, reg, rm });
    } else {
        try stdout.print("{s} {s} {s}", .{ opcode, rm, reg });
    }

    try bw.flush();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const stdout_file = std.io.getStdOut().writer();
    const allocator = arena.allocator();

    // Read byte content from input file
    const bytes = try read_file(allocator);

    // Decode the bytes and send to stdout
    try decode(bytes, stdout_file);
}
