const std = @import("std");
const protocol = @import("./protocol.zig");
const posix = std.posix;
const net = std.net;

pub fn main() !void {

    // Creates a TCP socket
    const server_sock = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    defer posix.close(server_sock);

    const addr = try net.Address.parseIp4("127.0.0.1", 4000);

    // bind socket to address
    posix.bind(server_sock, &addr.any, addr.getOsSockLen()) catch |err| {
        std.debug.print("Bind FAILED: {any}\n", .{err});
    };
    
    // listen for incoming connections
    try posix.listen(server_sock, 10);
    std.debug.print("Waiting for packets on socket...\n", .{});

    // accept connection
    var src_addr: posix.sockaddr = undefined;
    var src_addr_len: posix.socklen_t = @sizeOf(posix.sockaddr);
    const connection = try posix.accept(server_sock, &src_addr, &src_addr_len, 0);

    var i: u32 = 1;
    var bytes_received: usize = 1;
    while (bytes_received != 0) : (i += 1) {
       
        // Buffer for receiving packets
        var buffer: [1068]u8 = undefined;
        
        // Receive raw packets
        bytes_received = try posix.recv(connection, &buffer, 0);
        std.debug.print("{d} - Received {d} bytes from {any}\n", .{ i, bytes_received, src_addr.data[2..6] });

        // Output message
        std.debug.print("Data: ", .{});
        for (buffer[0..]) |b| {
            if (b == 170) {
                continue;
            }
            std.debug.print("{c}", .{b});
        }
        std.debug.print("\n", .{});
    }
}
