const std = @import("std");

const ip = struct { //
    version: u4,
    header_len: u4,
    tos: u6,
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
