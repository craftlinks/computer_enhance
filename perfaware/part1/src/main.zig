// TODO, Craft: better error handling?
// TODO: Maybe don't need allocator? Snoop from: https://gist.github.com/g-cassie/71365ed67f1ee99700decaccad551b8f
// TODO: use bufPrint to print in fixed buffer size slice.

const std = @import("std");
const fs = std.fs;
const Mov = @import("Mov.zig");

fn decode(buf: []u8, in_stream: anytype, asm_instruction_out: []u8) !void {
    
    if((buf[0] & 0b11111100) == 0b10001000) {try Mov.registerMemoryToFromMemory(buf, in_stream, asm_instruction_out);}
    else if((buf[0] & 0b11110000) == 0b1011) {try Mov.immediateToRegister(buf, in_stream, asm_instruction_out);}
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
