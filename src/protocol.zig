const std = @import("std");
const posix = std.posix;
const time = std.time;
const print = std.debug.print;

pub const Status = union(enum) { //
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

pub const FLAG = enum(u8) { //
    CWR = 1,
    ECE = 2,
    URG = 4,
    ACK = 8,
    PSH = 16,
    RST = 32,
    SYN = 64,
    FIN = 128,
    SYN_ACK = 8 & 64,
};

const addr_pair = struct {
    src_addr: [4]u8,
    src_port: u16,
    dst_addr: [4]u8,
    dst_port: u16,
};

const StreamSocket = struct {
    id: u16,
    socket_t: posix.socket_t,
};

// Transport Control Block
const TCB = struct {
    status: Status,

    addr_pair: *addr_pair,

    una_seq: u32, // unacknowledged seq number (current)
    nxt_seq: u32, // next sequence number
    nxt_rcv: u32, // next expected sequence number

    rcv_wnd: u16, // receive window size
    snd_wnd: u16, // send window size

    rcv_bfr: *[]const u8, // receive buffer
    snd_bfr: *[]const u8, // send buffer

    last_ack_time: i64, // ms since 1970-01-01
};

const StateMachine = struct {
    allocator: std.heap.ArenaAllocator,
    // TCB_tbl:
    // SOCK_tbl

    // Initialize Protocol
    pub fn init() StateMachine {
        // Init protocol allocator
        // Init Socket table
        // Init TCB table
    }

    // Cleanly shutdown the protocol
    pub fn shutdown(self: *StateMachine) void {
        // Prevents new connections
        // Resets existing connections
        // Free all allocated memory
        self.allocator.deinit();
    }

    // Returns a new TCP socket
    pub fn socket() !StreamSocket {}

    // Binds a socket to an address, storing it in the Socket table
    pub fn bind() !void {}

    // Requests a connection with a destination address that is listening
    pub fn connect() !void {}

    // Allows a socket to handle(i.e. queue) incoming connection requests
    pub fn listen() !void {}

    // Polls next queued connection request and establishes connection - BLOCKING
    pub fn accept() !void {}

    // Sends data to a connected destination
    pub fn send() !usize {}

    // Receives data to a connected destination
    pub fn recv() !usize {}
};
