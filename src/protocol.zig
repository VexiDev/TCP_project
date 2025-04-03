const std = @import("std");
const posix = std.posix;
const Ip4Address = std.net.Ip4Address;
const time = std.time;
const print = std.debug.print;

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
    SYN_ACK = 8 & 64,
};

// Transport Control Block
const TCB = struct {
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
    ) !TCB {
        const allocator = alloc.allocator();

        // init buffers
        const rcv_bfr = try allocator.alloc(u8, 1000);
        @memset(rcv_bfr, 0);
        const snd_bfr = try allocator.alloc(u8, 1000);
        @memset(snd_bfr, 0);

        return TCB{
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

// Returns a new posix socket
pub fn socket() !posix.socket_t {
    const sock = try posix.socket(posix.AF.INET, posix.SOCK.RAW, posix.IPPROTO.TCP);
    // -- DISABLE KERNEL IP HEADERS
    try std.posix.setsockopt(
        sock,
        std.os.linux.IPPROTO.IP,
        std.os.linux.IP.HDRINCL,
        &std.mem.toBytes(@as(c_int, 1)),
    );
    return sock;
}

// Closes an opened socket
pub fn close(socket_t: posix.socket_t) void {
    posix.close(socket_t);
}

// Binds a socket to an address
pub fn bind(socket_t: posix.socket_t, addr: Ip4Address) !void {
    const address = std.net.Address{ .in = addr };
    return posix.bind(socket_t, &address.any, address.getOsSockLen());
}

pub const StateMachine = struct {
    allocator: std.heap.ArenaAllocator,
    TCB_table: std.AutoHashMap(Ip4Address, *TCB), // dest_addr, TCB
    connections: std.AutoHashMap(posix.socket_t, Ip4Address), // src_addr, socket

    // Initialize Protocol
    pub fn init(allocator: std.mem.Allocator) !*StateMachine {
        // Init protocol allocator
        const arena_ptr = try allocator.create(std.heap.ArenaAllocator);
        arena_ptr.* = std.heap.ArenaAllocator.init(allocator);
        const self = try allocator.create(StateMachine);

        self.* = StateMachine{
            .allocator = arena_ptr.*,
            // Init TCB table
            .TCB_table = std.AutoHashMap(Ip4Address, *TCB).init(arena_ptr.allocator()),
            // Init Socket table
            .connections = std.AutoHashMap(posix.socket_t, Ip4Address).init(arena_ptr.allocator()),
        };

        return self;
    }

    // Cleanly shutdown the protocol
    pub fn shutdown(self: *StateMachine) void {
        // Prevents new connections
        // Resets existing connections
        // Free all allocated memory
        self.TCB_table.deinit();
        self.connections.deinit();
        self.allocator.deinit();
    }

    // Requests a connection with a destination address that is listening
    pub fn connect(self: *StateMachine, socket_t: posix.socket_t, dest_addr: Ip4Address) !void {
        if (self.connections.contains(socket_t)) return error.SocketAlreadyConnected;
        if (self.TCB_table.contains(dest_addr)) return error.AddressInUse;

        // bind destination to socket
        try self.connections.put(socket_t, dest_addr);

        // bind TCB to address
        const allocator = self.allocator.allocator();
        const blank_tcb = try allocator.create(TCB);
        blank_tcb.* = try TCB.init(dest_addr, dest_addr, &self.allocator);
        try self.TCB_table.put(dest_addr, blank_tcb);

        // TODO: 3w handshake implementation
    }

    // Allows a socket to handle(i.e. queue) incoming connection requests
    //pub fn listen(self: *StateMachine) !void {}

    // Polls next queued connection request and establishes connection - BLOCKING
    //pub fn accept(self: *StateMachine) !void {}

    // Sends data to a connected destination
    pub fn send(self: *StateMachine, socket_t: posix.socket_t, buf: *[]const u8) !usize {
        // Get socket info:
        // -> Get destination from TCB block
        const dest_addr: ?Ip4Address = self.connections.get(socket_t);
        if (dest_addr == null) return error.SocketNotConnected;
        const connection_TCB: ?*TCB = self.TCB_table.get(dest_addr.?);
        if (connection_TCB == null) return error.AddressMissingTCB;

        // IP:
        // -> Build IP header

        // TCP:
        // -> Get TCB block of address
        // -> Build TCP header

        // Build full packet
        const ip_len = 20;
        const tcp_len = 20;
        const max_data_size = 1000;
        const max_packet_size = ip_len + tcp_len + max_data_size;
        std.debug.print("Expected packet header length: {}\n", .{ip_len + tcp_len});

        // Allocate buffer
        var packet_buffer: [max_packet_size]u8 = undefined;

        // IP Header
        packet_buffer[0] = 0x45; // Version+IHL
        packet_buffer[1] = 0x00; // TOS
        packet_buffer[2] = 0x00;
        packet_buffer[3] = 0x37; // Total length (0x0037)
        packet_buffer[4] = 0x00;
        packet_buffer[5] = 0x00; // ID
        packet_buffer[6] = 0x00;
        packet_buffer[7] = 0x00; // Flags+Fragment offset
        packet_buffer[8] = 64; // TTL
        packet_buffer[9] = 6; // Protocol (TCP)
        packet_buffer[10] = 0x22;
        packet_buffer[11] = 0xAE; // Header checksum
        packet_buffer[12] = 172;
        packet_buffer[13] = 25;
        packet_buffer[14] = 0;
        packet_buffer[15] = 3; // Source IP
        packet_buffer[16] = 172;
        packet_buffer[17] = 25;
        packet_buffer[18] = 0;
        packet_buffer[19] = 2; // Destination IP

        // TCP Header
        const tcp_start = ip_len;
        packet_buffer[tcp_start + 0] = 0x0F;
        packet_buffer[tcp_start + 1] = 0xA1; // Source port (4001)
        packet_buffer[tcp_start + 2] = 0x0F;
        packet_buffer[tcp_start + 3] = 0xA0; // Destination port (4000)
        packet_buffer[tcp_start + 4] = 0x00;
        packet_buffer[tcp_start + 5] = 0x00;
        packet_buffer[tcp_start + 6] = 0x00;
        packet_buffer[tcp_start + 7] = 0x00; // Seq num
        packet_buffer[tcp_start + 8] = 0x00;
        packet_buffer[tcp_start + 9] = 0x00;
        packet_buffer[tcp_start + 10] = 0x00;
        packet_buffer[tcp_start + 11] = 0x00; // Ack num
        packet_buffer[tcp_start + 12] = 0x50; // Data offset (5 << 4), Reserved
        packet_buffer[tcp_start + 13] = 0x02; // Flags (SYN)
        packet_buffer[tcp_start + 14] = 0x20;
        packet_buffer[tcp_start + 15] = 0x00; // Window size (8192)
        packet_buffer[tcp_start + 16] = 0x51;
        packet_buffer[tcp_start + 17] = 0x85; // Checksum
        packet_buffer[tcp_start + 18] = 0x00;
        packet_buffer[tcp_start + 19] = 0x00; // Urgent pointer

        // Data
        const data_start = ip_len + tcp_len;
        std.mem.copyForwards(u8, packet_buffer[data_start..], buf.*);

        // truncate unused
        const final_packet = packet_buffer[0 .. data_start + buf.len];
        std.debug.print("Final packet length: {}\n", .{final_packet.len});

        // Send to destination address through raw socket
        const address = std.net.Address{ .in = dest_addr.? };

        print("Sending to {any}\n", .{address});

        return posix.sendto(socket_t, final_packet, 0, &address.any, dest_addr.?.getOsSockLen());
    }

    // Receives data to a connected destination
    pub fn recv() !usize {}
};
