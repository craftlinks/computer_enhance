// TODO, Craft: better error handling?
// TODO: Maybe don't need allocator? Snoop from: https://gist.github.com/g-cassie/71365ed67f1ee99700decaccad551b8f
// TODO: use bufPrint to print in fixed buffer size slice.

const std = @import("std");
const fs = std.fs;

const MOV = struct {
    fn registerMemoryToFromMemory(buf: []u8, in_stream: anytype, asm_instruction_out: []u8) !void {
        // d == 1 -> REG is destination operand
        // d == 0 -> REG is source operand
        const d = if ((buf[0] & 0b00000010) == 0b00000010) true else false;

        // w == 1 -> word(16-bit) data;
        // w == 0 -> byte(8-bit) data;
        const w = if ((buf[0] & 0b00000001) == 0b00000001) true else false;

        // fetch next byte in stream
        _ = try in_stream.read(buf);

        // mod == 11 -> register-to-register mode, only one allowed. Crash otherwise.
        const mod = buf[0] & 0b11000000;
        if (mod != 0b11000000) {
            std.debug.print("MOD must be '0b11000000', found {b}", .{mod});
            unreachable;
        }

        const reg = decode_register(buf[0] & 0b00111000, w);
        const rm = decode_register(buf[0] & 0b00000111, w);

        if (d) {
            _ = try std.fmt.bufPrint(asm_instruction_out, "mov {s}, {s} \n", .{ reg, rm });
        } else {
            _ = try std.fmt.bufPrint(asm_instruction_out, "mov {s}, {s} \n", .{ rm, reg });
        }
    }

    fn immediateToRegister(buf: []u8, in_stream: anytype, asm_instruction_out: []u8) !void {
        _ = buf;
        _ = in_stream;
        _ = asm_instruction_out;
    }
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

fn decode(buf: []u8, in_stream: anytype, asm_instruction_out: []u8) !void {
    
    if((buf[0] & 0b11111100) == 0b10001000) {try MOV.registerMemoryToFromMemory(buf, in_stream, asm_instruction_out);}
    else if((buf[0] & 0b11110000) == 0b1011) {try MOV.immediateToRegister(buf, in_stream, asm_instruction_out);}
    else unreachable;
}

pub fn main() !void {

    // Memory arena
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Get file path from command line.
    const args = try std.process.argsAlloc(allocator);
    if (args.len != 2) {
        std.debug.print("Required argument: path to Binary File\n", .{});
        unreachable;
    }
    const binary_file_path = args[1];

    // Prepare stdout
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Open file and prepare buffered stream reader.
    const file = try std.fs.cwd().openFile(binary_file_path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    const in_stream = buf_reader.reader();

    // Decode 1 byte at a time.
    var buf: [1]u8 = [_]u8{0};
    
    try stdout.print("bits 16\n\n", .{});

    // Assume an assembly instruction will never exceed 100 bytes in length.
    var asm_instruction: [100]u8 = [_]u8{0} ** 100;
    while (try in_stream.read(&buf) > 0) {
        try decode(&buf, in_stream, &asm_instruction);
        try stdout.writeAll(&asm_instruction);
        try bw.flush();
    }
}
