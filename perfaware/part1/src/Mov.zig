const std = @import("std");
const registers = @import("registers.zig");
const decode_register = registers.decode_register;

pub fn registerMemoryToFromMemory(buf: []u8, in_stream: anytype, asm_instruction_out: []u8) !void {
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

pub fn immediateToRegister(buf: []u8, in_stream: anytype, asm_instruction_out: []u8) !void {
    _ = buf;
    _ = in_stream;
    _ = asm_instruction_out;
}
