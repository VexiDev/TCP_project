const std = @import("std");
const posix = std.posix;

const tcp = @import("tcp.zig");
const ip = @import("ip.zig");
const icmp = @import("icmp.zig");

const Ip4Address = std.net.Ip4Address;
const time = std.time;
const print = std.debug.print;

// Returns a new posix socket
pub fn socket() !posix.socket_t {
    const sock = try posix.socket(posix.AF.INET, posix.SOCK.RAW, posix.IPPROTO.TCP);
    // -- DISABLE KERNEL IP HEADER
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

// Binds a socket to an Address
// -
// Since we are not filtering packets directly off the wire we just bind our raw socket to an address and have the
// kernel pass TCP packets for that address to our socket. This probably adds some overhead since packets go through the kernel stack
// but, as of now, speed isn't a priority focus for this project so its acceptable.
pub fn bind(socket_t: posix.socket_t, addr: Ip4Address) !void {
    const address = std.net.Address{ .in = addr };
    return posix.bind(socket_t, &address.any, address.getOsSockLen());
}

pub const StateMachine = struct {
    allocator: std.heap.ArenaAllocator,
    TCB_table: std.AutoHashMap(Ip4Address, *tcp.tcb_t), // dest_addr, TCB
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
            .TCB_table = std.AutoHashMap(Ip4Address, *tcp.tcb_t).init(arena_ptr.allocator()),
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
        const blank_tcb = try allocator.create(tcp.tcb_t);
        blank_tcb.* = try tcp.tcb_t.init(dest_addr, dest_addr, &self.allocator);
        try self.TCB_table.put(dest_addr, blank_tcb);

        // TODO: 3w handshake implementation
    }

    // Allows a socket to handle(i.e. queue) incoming connection requests
    //pub fn listen(self: *StateMachine) !void {}

    // Polls next queued connection request and establishes connection - BLOCKING
    //pub fn accept(self: *StateMachine) !void {}

    // Sends buf to dest_addr using IPv4
    pub fn sendto(self: *StateMachine, socket_t: posix.socket_t, buf: *[]const u8, src_addr: Ip4Address, dest_addr: Ip4Address) !usize {
        _ = self;
        _ = buf;
        var packet: [28]u8 = undefined;
        try ip.build(&packet, src_addr, dest_addr, 1, 8);

        // insert ICMP
        try icmp.icmp_ping(&packet, false);

        const address = std.net.Address{ .in = dest_addr };
        return posix.sendto(socket_t, &packet, 0, &address.any, dest_addr.getOsSockLen());
    }

    // Sends data to a connected destination
    pub fn send(self: *StateMachine, socket_t: posix.socket_t, buf: *[]const u8) !usize {
        const ip_len = 20;
        const tcp_len = 20;
        const max_data_size = 1000;
        const max_packet_size = ip_len + tcp_len + max_data_size;

        if (buf.*.len > max_data_size) return error.DataTooBig;

        // Get socket info:
        // -> Get destination from TCB block
        const src_addr = try Ip4Address.resolveIp("0.0.0.0", 4001);
        const dest_addr: ?Ip4Address = self.connections.get(socket_t);
        if (dest_addr == null) return error.SocketNotConnected;
        const connection_TCB: ?*tcp.tcb_t = self.TCB_table.get(dest_addr.?);
        if (connection_TCB == null) return error.AddressMissingTCB;


        // TCP:
        // -> Get TCB block of address
        // -> Build TCP header
        //const tcp_hdr_buf: [tcp_len]u8 = undefined;
        //tcp.build(tcp_hdr_buf, connection_TCB, buf.*.len);

        // IP:
        // -> Build IP header
        var ip_hdr_buf: [ip_len]u8 = undefined;
        const data_len: u16 = @intCast(buf.*.len);
        try ip.build(&ip_hdr_buf, src_addr, dest_addr.?, ip.PROTCOL.TCP, data_len);

        // Build full packet
        std.debug.print("Expected header lengths: IP={}, TCP={}\n", .{ ip_len, tcp_len });
        std.debug.print("Data size: {}\n", .{buf.*.len});

        // Allocate buffer
        var packet_buffer: [max_packet_size]u8 = undefined;

        // IP Header
        std.mem.copyForwards(u8, packet_buffer[0..ip_len], &ip_hdr_buf);

        // TCP Header
        const tcp_start = ip_len;
        // Source port (4001)
        packet_buffer[tcp_start + 0] = 0x0F;
        packet_buffer[tcp_start + 1] = 0xA1;
        // Destination port (4000)
        packet_buffer[tcp_start + 2] = 0x0F;
        packet_buffer[tcp_start + 3] = 0xA0;
        // Seq num
        packet_buffer[tcp_start + 4] = 0x00;
        packet_buffer[tcp_start + 5] = 0x00;
        packet_buffer[tcp_start + 6] = 0x00;
        packet_buffer[tcp_start + 7] = 0x00;
        // Ack num
        packet_buffer[tcp_start + 8] = 0x00;
        packet_buffer[tcp_start + 9] = 0x00;
        packet_buffer[tcp_start + 10] = 0x00;
        packet_buffer[tcp_start + 11] = 0x00;
        // Data offset (5 << 4), Reserved
        packet_buffer[tcp_start + 12] = 0x50;
        // Flags (SYN)
        packet_buffer[tcp_start + 13] = 0x02;
        // Window size (8192)
        packet_buffer[tcp_start + 14] = 0x20;
        packet_buffer[tcp_start + 15] = 0x00;
        // Checksum
        packet_buffer[tcp_start + 16] = 0x51;
        packet_buffer[tcp_start + 17] = 0x85;
        // Urgent pointer
        packet_buffer[tcp_start + 18] = 0x00;
        packet_buffer[tcp_start + 19] = 0x00;

        // Data
        const data_start = ip_len + tcp_len;
        std.mem.copyForwards(u8, packet_buffer[data_start..], buf.*);

        // truncate unused
        const final_packet = packet_buffer[0 .. data_start + buf.*.len];
        std.debug.print("Final packet length: {}\n", .{final_packet.len});

        // Send to destination address through raw socket
        const address = std.net.Address{ .in = dest_addr.? };

        print("Sending to {any}\n", .{address});

        return posix.sendto(socket_t, final_packet, 0, &address.any, dest_addr.?.getOsSockLen());
    }

    // Receives data from a connected destination
    pub fn recv(self: *StateMachine, socket_t: posix.socket_t, buf: *[]u8) !usize {
        // Get socket info:
        // -> Get from addr TCB block
        _ = self;
        //const conn_addr: ?Ip4Address = self.connections.get(socket_t);
        //if (conn_addr == null) return error.SocketNotConnected;
        //const connection_TCB: ?TCB = self.TCB_table.get(conn_addr);
        //if (connection_TCB == null) return error.AddressMissingTCB;

        var from_addr: posix.sockaddr = undefined;
        var from_addr_len: posix.socklen_t = @sizeOf(posix.sockaddr);
        const bytes = posix.recvfrom(socket_t, buf.*, 0, &from_addr, &from_addr_len) catch |err| {
            return err;
        };

        // IP:
        // -> Parse IP header
        // -> Validate IP

        // TCP:
        // -> Parse TCP header
        // -> Get TCB block of address
        // -> Cast TCP magic to ensure correctness

        return bytes;
    }
};
