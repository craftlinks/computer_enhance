// TODO, Craft: better error handling?
// TODO: Maybe don't need allocator? Snoop from: https://gist.github.com/g-cassie/71365ed67f1ee99700decaccad551b8f
// TODO: use bufPrint to print in fixed buffer size slice.

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

fn decode_register(byte: u8, w: bool) *const [2:0]u8 {
    const reg = switch (byte) {
        0b00000000 => if (w) "ax" else "al",
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

fn registerMemoryToFromMemory(buf: [1]u8, in_stream: anytype, decoded_string: []u8) ![]u8 {
    // d == 1 -> REG is destination operand
    // d == 0 -> REG is source operand
    const d = if ((buf & 0b00000010) == 0b00000010) true else false;

    // w == 1 -> word(16-bit) data;
    // w == 0 -> byte(8-bit) data;
    const w = if ((buf & 0b00000001) == 0b00000001) true else false;

    // mod == 11 -> register-to-register mode, only one allowed. Crash otherwise.
    const mod = buf & 0b11000000;
    if (mod != 0b11000000) {
        std.debug.print("MOD must be '0b11000000', found {d}", .{mod});
        unreachable;
    }

    _ = in_stream.read(&buf);

    const reg = decode_register(buf & 0b00111000, w);
    const rm = decode_register(buf & 0b00000111, w);

    if (d) {
        const string = try std.fmt.bufPrint(&decoded_string, "mov {s}, {s} \n", .{ reg, rm });
        return string;
    } else {
        const string = try std.fmt.allocPrint(&decoded_string, "mov {s}, {s} \n", .{ rm, reg });
        return string;
    }
}

fn immediateToRegister(buf: [1]u8) ![]u8 {
    _ = buf;
    return "";
}

fn decode(buf: [1]u8, in_stream: anytype) ![]u8 {
    const decoded = switch (buf) {
        (buf & 0b11111100) == 0b10001000 => registerMemoryToFromMemory(buf, in_stream),
        (buf & 0b11110000) == 0b1011 => immediateToRegister(buf, in_stream),
        else => unreachable,
    };

    return decoded;
}

pub fn main() !void {

    // Memory arena
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // stdout
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Get file path from command line
    const args = try std.process.argsAlloc(allocator);
    if (args.len != 2) {
        std.debug.print("Required argument: path to Binary File\n", .{});
        unreachable;
    }
    const binary_file_path = args[1];

    // Open file and prepare buffered stream reader.
    const file = try std.fs.cwd().openFile(binary_file_path, .{});
    defer file.close();

    const buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    // Read and decode 1 byte at a time
    var buf: [1]u8 = [_]u8{0};
    try stdout.print("bits 16\n\n", .{});

    var asm_instruction: [100]u8 = [_]u8{0} ** 100;
    while (try in_stream.read(&buf) > 0) {
        try decode(&buf, in_stream, &asm_instruction);
        try stdout.writeAll(asm_instruction);
        try bw.flush();
    }
}
