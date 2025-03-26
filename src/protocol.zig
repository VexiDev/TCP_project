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

const TCP = struct {
    allocator: std.heap.ArenaAllocator,
    // TCB_tbl:
    // SOCK_tbl

    // Initialize Protocol
    pub fn init() TCP {
        // Init protocol allocator
        // Init Socket table
        // Init TCB table
    }

    // Cleanly shutdown the protocol
    pub fn shutdown(self: *TCP) void {
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
