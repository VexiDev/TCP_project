const std = @import("std");
const rand = std.crypto.random;

const icmp_ping_t = packed struct { //
    type: u8,
    code: u8,
    checksum: u16,
    id: u16,
    seq: u16,
};

pub fn icmp_ping(hdr_out: *[28]u8, reply: bool) !void {
    var header = icmp_ping_t{ //
        .type = if (reply) 0 else 8,
        .code = 0,
        .checksum = 0,
        .id = rand.int(u16), // random eventually
        .seq = rand.int(u16), // random eventually
    };

    // compute checksum
    var hdr_u8_buf: [8]u8 = undefined;
    pack_icmp_ping_hdr(&hdr_u8_buf, header);
    const sum = icmp_ping_hdr_checksum(hdr_u8_buf);
    header.checksum = sum;
    pack_icmp_ping_hdr(&hdr_u8_buf, header);

    // validate checksum
    if (icmp_ping_hdr_checksum(hdr_u8_buf) != 0) {
        return error.InvalidCheckSum;
    }

    // fill hdr out with header
    for (hdr_u8_buf, 20..28) |byte, i| {
        hdr_out.*[i] = byte;
    }
}

fn pack_icmp_ping_hdr(buf: *[8]u8, hdr: icmp_ping_t) void {
    buf[0] = hdr.type;
    buf[1] = hdr.code;
    std.mem.writeInt(u16, buf[2..4], hdr.checksum, .big);
    std.mem.writeInt(u16, buf[4..6], hdr.id, .big);
    std.mem.writeInt(u16, buf[6..8], hdr.seq, .big);
}

fn icmp_ping_hdr_checksum(buf: [8]u8) u16 {
    var sum: u16 = 0;
    var i: usize = 0;
    while (i + 1 < buf.len) : (i += 2) {
        const word = std.mem.readInt(u16, buf[i..][0..2], .big);
        sum +%= word;
    }
    return ~sum;
}
