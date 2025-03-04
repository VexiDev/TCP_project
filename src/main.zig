const std = @import("std");
const posix = std.posix;
const net = std.net;

const AF_INET: u32 = 2;
const SOCK_RAW: u32 = 3;
const IPPROTO_TESTING: u32 = 253;

pub fn main() !void {

    // Creates a raw socket using an unused protocol
    const server_socket = try posix.socket(posix.AF.INET, posix.SOCK.RAW, 253);
    defer posix.close(server_socket);

    // Set receive address (this is optional)
    const addr = try net.Address.parseIp4("127.0.0.1", 4000);

    // Apparently bind is optional for raw sockets? research
    posix.bind(server_socket, &addr.any, addr.getOsSockLen()) catch |err| {
        std.debug.print("Bind FAILED: {any}\n", .{err});
    };

    std.debug.print("Waiting for packets on raw socket...\n", .{});
    var i: u32 = 0;
    while (true) : (i += 1) {
        // Buffer for receiving packets
        var buffer: [2048]u8 = undefined;
        var src_addr: posix.sockaddr = undefined;
        var src_addr_len: posix.socklen_t = @sizeOf(posix.sockaddr);

        // Receive raw packets
        const bytes_received = try posix.recvfrom(server_socket, &buffer, 0, &src_addr, &src_addr_len);

        std.debug.print("{d} - Received {d} bytes from {any}\n", .{i, bytes_received, src_addr.data[2..6]});
    }
}
