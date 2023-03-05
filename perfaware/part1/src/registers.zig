pub fn decode_register(byte: u8, w: bool) *const [2:0]u8 {
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