const std = @import("std");
const protocol = @import("./protocol.zig");
const posix = std.posix;
const net = std.net;

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

    var i: u32 = 1;
    while (true) : (i += 1) {
        // Buffer for receiving packets
        var buffer: [1068]u8 = undefined;
        var src_addr: posix.sockaddr = undefined;
        var src_addr_len: posix.socklen_t = @sizeOf(posix.sockaddr);

        // Receive raw packets
        const bytes_received = try posix.recvfrom(server_socket, &buffer, 0, &src_addr, &src_addr_len);
        std.debug.print("{d} - Received {d} bytes from {any}\n", .{ i, bytes_received, src_addr.data[2..6] });

        // Deserialize TCP Header
        const header = protocol.Header.deserialize(buffer[20..44]);

        // Output message
        std.debug.print("Data: ", .{});
        for (buffer[44..]) |b| { // 44 -> 20 + 24 -> IP Header + TCP Header
            if (b == 170) {
                continue;
            }
            std.debug.print("{c}", .{b});
        }
        std.debug.print("\n", .{});
        std.debug.print("{any}\n", .{header});
    }
}
