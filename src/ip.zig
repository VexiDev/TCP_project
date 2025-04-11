const std = @import("std");

const Ip4Address = std.net.Ip4Address;

const ip_hdr = packed struct { //
    version: u4,
    header_len: u4,
    dscp: u6,
    ecn: u2,
    total_len: u16,
    id: u16,
    flags: u3,
    frag_offset: u13,
    ttl: u8,
    protocol: u8,
    hdr_checksum: u16,
    src_addr: u32,
    dest_addr: u32,
};

pub fn build( //
    hdr_out: *[]u8,
    src: Ip4Address,
    dest: Ip4Address,
    proto: u8,
    data_len: u16,
) !void { //
    _ = proto;

    // build ip header struct
    const header = ip_hdr{
        .ver = 4, // ipv4
        .len = 5, // 5 * 32 bit words -> 20 bytes
        .dscp = 0, // diffserv -> normal traffic
        .ecn = 0, // does not support ECN (for now)
        .total_len = add(20, data_len), // total length of packet
        .id = 42069, // id value (will be random eventually)
        .flags = 2, // 010 -> don't fragment
        .frag_offset = 0, // to know which fragment relative of the first
        .ttl = 20, // time to live -> j setting to 20 for now will change as I read more RFCs
        .protocol = 1, // ICMP for now -> will use the proto argument eventually
        .checksum = 0, // computed at end
        .src_addr = src.sa.addr,
        .dest_addr = dest.sa.addr,
    };

    // compute checksum
    const sum = checksum(header);
    header.hdr_checksum = sum;

    // validate checksum
    if (checksum(header) != 0) {
        return error.InvalidCheckSum;
    }

    // fill packet out with header
    const ptr: *const [20]u8 = @ptrCast(@as(*const u8, &ip_hdr));
    const arr: [20]u8 = ptr.*;
    for (arr, 0..20) |byte, i| {
        hdr_out.*[i] = byte;
    }
}

fn add(a: u16, b: u16) u16 {
    return a + b;
}

fn checksum(hdr: ip_hdr) u16 {
    const ptr: *const [10]u16 = @ptrCast(@as(*const u8, &hdr));
    const arr: [10]u16 = ptr.*;
    var sum: u16 = 0;
    for (arr) |v| {
        sum +%= v; // overflow wrapping sum
    }
    return ~sum; // bitwise NOT
}
