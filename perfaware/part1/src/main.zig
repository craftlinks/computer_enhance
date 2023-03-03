const std = @import("std");
const fs = std.fs;

const FILE_NAME = "listing_0037_single_register_mov";

const Opcode = enum(u8)  {
    mov = 0b10001000,
    undefined,
};

const Instruction = struct {
    opcode: Opcode,

};

pub fn main() !void {

    // Read in a binary file, atore the contents in a variable of type byte-array?
    // Move to its own function...

    const cwd: fs.Dir = fs.cwd();
    var outBuffer = [_]u8{0} ** 256;
    const realPath = try cwd.realpath("./", &outBuffer);

    std.debug.print("read file from CWD: {s}\\{s} \n", .{ realPath, FILE_NAME });

    var inBuffer = [_]u8{0} ** 2;
    const bytes = try cwd.readFile(FILE_NAME, &inBuffer);
    
    // Print the binary contents of the bytes.
    std.debug.print("File Contents: {b} \n", .{bytes});

    // Match the bit-string and construct the assembly instructions
    // First 6 bits determines the opcode
    // bit 7 = D
    // bit 8 = w
    // bits 9 - 10 = MOD
    // bits 11 - 13 = REG
    // bits 14 - 16 = R/M


    const OPERAND_MASK = 0b11111100;
    // const D_M = 0b00000010;
    // const W_M = 0b00000001;
    // const MOD_M = 0b11000000;
    // const REG_M = 0b00111000;
    // const RM_M = 0b00000011;


    // Put in a Decoder Function that returns an Instruction struct

    const opcode = switch (bytes[0] & OPERAND_MASK) {
        @enumToInt(Opcode.mov) => Opcode.mov,
        else => Opcode.undefined,
    };

    const instruction: Instruction = .{
        .opcode = opcode,
    };

    std.debug.print("opcode: {s} \n", .{@tagName(instruction.opcode)});

    // send to std out

    // Put in own function that generates the asm output to stdout.

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    _ = stdout;
    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
