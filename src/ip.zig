const std = @import("std");

const Ip4Address = std.net.Ip4Address;

fn add(a: u16, b: u16) u16 {
    return a + b;
}

pub const PROTCOL = enum(u8) {
    ICMP = 1,
    TCP = 6,
};

const ip_hdr = packed struct { //
    ver: u4,
    len: u4,
    dscp: u6,
    ecn: u2,
    total_len: u16,
    id: u16,
    flags: u3,
    frag_offset: u13,
    ttl: u8,
    protocol: u8,
    checksum: u16,
    src_addr: u32,
    dest_addr: u32,
};

pub fn build( //
    hdr_out: *[20]u8,
    src: Ip4Address,
    dest: Ip4Address,
    proto: PROTCOL,
    data_len: u16, // in bytes
) !void { //
    _ = proto;

    // build ip header struct
    var header = ip_hdr{
        .ver = 4, // ipv4
        .len = 5, // 5 * 32 bit words -> 20 bytes
        .dscp = 0, // diffserv -> normal traffic
        .ecn = 0, // does not support ECN (for now)
        .total_len = add(20, data_len), // total length of packet
        .id = 42069, // id value (will be random eventually)
        .flags = 2, // 010 -> don't fragment
        .frag_offset = 0, // to know which fragment relative of the first
        .ttl = 20, // time to live -> j setting to 20 for now will change as I read more RFCs
        .protocol = 6, // ICMP for now -> will use the proto argument eventually
        .checksum = 0, // computed later
        .src_addr = src.sa.addr,
        .dest_addr = dest.sa.addr,
    };

    // compute checksum
    var hdr_u8_buf: [20]u8 = undefined;
    pack_ip_hdr(&hdr_u8_buf, header);
    var sum = ip_hdr_checksum(hdr_u8_buf);
    header.checksum = sum;
    pack_ip_hdr(&hdr_u8_buf, header);

    // validate checksum
    sum = ip_hdr_checksum(hdr_u8_buf);
    if (sum != 0) {
        return error.InvalidCheckSum;
    }

    // fill packet out with header
    for (hdr_u8_buf, 0..20) |byte, i| {
        hdr_out.*[i] = byte;
    }
}

fn pack_ip_hdr(buf: *[20]u8, hdr: ip_hdr) void {
    buf[0] = (@as(u8, hdr.ver) << 4) | @as(u8, hdr.len);
    buf[1] = (hdr.dscp << 2) | hdr.ecn;
    std.mem.writeInt(u16, buf[2..4], hdr.total_len, .big);
    std.mem.writeInt(u16, buf[4..6], hdr.id, .big);
    std.mem.writeInt(u16, buf[6..8], (@as(u16, hdr.flags) << 13) | hdr.frag_offset, .big);
    buf[8] = hdr.ttl;
    buf[9] = hdr.protocol;
    std.mem.writeInt(u16, buf[10..12], hdr.checksum, .big);
    std.mem.writeInt(u32, buf[12..16], hdr.src_addr, .little);
    std.mem.writeInt(u32, buf[16..20], hdr.dest_addr, .little);
}

fn ip_hdr_checksum(buf: [20]u8) u16 {
    var sum: u16 = 0;
    var i: usize = 0;
    while (i + 1 < buf.len) : (i += 2) {
        const word = std.mem.readInt(u16, buf[i..][0..2], .big);
        sum +%= word;
    }
    return ~sum;
}
