const std = @import("std");
const Ip4Address = std.net.Ip4Address;


const TCP = @This();

const Status = union(enum) { //
    LISTEN,
    SYN_SENT,
    SYN_RECEIVED,
    ESTABLISHED,
    FIN_WAIT_1,
    FIN_WAIT_2,
    CLOSE_WAIT,
    CLOSING,
    LAST_ACK,
    TIME_WAIT,
    CLOSED,
};

const FLAG = enum(u8) { //
    CWR = 1,
    ECE = 2,
    URG = 4,
    ACK = 8,
    PSH = 16,
    RST = 32,
    SYN = 64,
    FIN = 128,
    SYN_ACK = 8 | 64,
};

// Transport Control Block
pub const tcb_t = struct {
    status: Status,

    una_seq: u32, // unacknowledged seq number (current)
    nxt_rcv: u32, // next expected sequence number
    nxt_seq: u32, // next sequence number

    rcv_wnd: u16, // receive window size
    snd_wnd: u16, // send window size

    rcv_bfr: []u8, // receive buffer
    snd_bfr: []u8, // send buffer

    src_addr: Ip4Address,
    dest_addr: Ip4Address,

    last_ack_time: i64, // ms since 1970-01-01

    pub fn init(
        src_addr: Ip4Address,
        dest_addr: Ip4Address,
        alloc: *std.heap.ArenaAllocator,
    ) !tcb_t {
        const allocator = alloc.allocator();

        // init buffers
        const rcv_bfr = try allocator.alloc(u8, 1000);
        @memset(rcv_bfr, 0);
        const snd_bfr = try allocator.alloc(u8, 1000);
        @memset(snd_bfr, 0);

        return tcb_t{
            .status = Status.CLOSED,

            .una_seq = 1,
            .nxt_rcv = 1,
            .nxt_seq = 2,

            .rcv_wnd = 1000,
            .snd_wnd = 1000,

            .rcv_bfr = rcv_bfr,
            .snd_bfr = snd_bfr,

            .src_addr = src_addr,
            .dest_addr = dest_addr,

            .last_ack_time = 0,
        };
    }
};
