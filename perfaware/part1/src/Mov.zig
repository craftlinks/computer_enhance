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

    const mod = buf[0] & 0b11000000;

    const reg = decode_register(buf[0] & 0b00111000, w);

    // Register to Register
    if (mod == 0b11000000) {
        const rm = decode_register(buf[0] & 0b00000111, w);

        if (d) {
            _ = try std.fmt.bufPrint(asm_instruction_out, "mov {s}, {s} \n", .{ reg, rm });
        } else {
            _ = try std.fmt.bufPrint(asm_instruction_out, "mov {s}, {s} \n", .{ rm, reg });
        }
    }

    // Effective Address Calculation
    else {
        const rm = buf[0] & 0b00000111;

        const result = switch (rm) {
            0b00000000 => "bx + si",
            0b00000001 => "bx + di",
            0b00000010 => "bp + si",
            0b00000011 => "bp + di",
            0b00000100 => "si",
            0b00000101 => "di",
            0b00000110 => "bp",
            0b00000111 => "bx",
            else => unreachable,
        };

        switch (mod) {
            0b00000000 => {
                if (rm == 0b00000110) {
                    std.debug.print("DIRECT ADDRESS THINGY\n", .{});
                    unreachable;
                } else {
                    if (d) {
                        _ = try std.fmt.bufPrint(asm_instruction_out, "mov {s}, [{s}]\n", .{ reg, result });
                    } else {
                        _ = try std.fmt.bufPrint(asm_instruction_out, "mov [{s}], {s}\n", .{ result, reg });
                    }
                }
            },
            0b01000000 => {
                // we need to fetch DATA-8
                _ = try in_stream.read(buf);
                if (d) {
                    if (buf[0] != 0) {
                        _ = try std.fmt.bufPrint(asm_instruction_out, "mov {s}, [{s} + {d}]\n", .{ reg, result, buf[0] });
                    }
                    else {
                         _ = try std.fmt.bufPrint(asm_instruction_out, "mov {s}, [{s}]\n", .{ reg, result});
                    }
                    
                } else {
                    if (buf[0] != 0) {
                        _ = try std.fmt.bufPrint(asm_instruction_out, "mov [{s} + {d}], {s}\n", .{ result, buf[0], reg });

                    }
                    else {
                        _ = try std.fmt.bufPrint(asm_instruction_out, "mov [{s}], {s}\n", .{ result, reg });
                    }
                }
            },
            0b10000000 => {
                // advance to first byte of data
                _ = try in_stream.read(buf);

                var data: u16 = @as(u16, buf[0]);

                // advance to second byte of data
                _ = try in_stream.read(buf);
                var data_2: u16 = @as(u16, buf[0]);
                // move over 8 bits to the left
                data_2 <<= 8;
                data ^= data_2;

                if (d) {
                    _ = try std.fmt.bufPrint(asm_instruction_out, "mov {s}, [{s} + {d}]\n", .{ reg, result, data });
                } else {
                    _ = try std.fmt.bufPrint(asm_instruction_out, "mov [{s} + {d}], {s}\n", .{ result, data, reg });
                }
            },
            else => unreachable,
        }
    }
}

pub fn immediateToRegister(buf: []u8, in_stream: anytype, asm_instruction_out: []u8) !void {

    // w == 1 -> word(16-bit) data;
    // w == 0 -> byte(8-bit) data;
    const w = if ((buf[0] & 0b00001000) == 0b00001000) true else false;
    const reg = decode_register(buf[0] & 0b00000111, w);

    // advance to first byte of data
    _ = try in_stream.read(buf);

    var data: u16 = @as(u16, buf[0]);

    // advance to second byte of data
    _ = try in_stream.read(buf);

    if (w) {
        var data_2: u16 = @as(u16, buf[0]);
        // move over 8 bits to the left
        data_2 <<= 8;
        data ^= data_2;
    }

    _ = try std.fmt.bufPrint(asm_instruction_out, "mov {s}, {any} \n", .{ reg, data });
}
