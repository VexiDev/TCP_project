const std = @import("std");
const posix = std.posix;
const net = std.net;

pub fn main() !void {

    // Create a raw socket with the same protocol as server (253)
    const client_socket = try posix.socket(posix.AF.INET, posix.SOCK.RAW, 253);
    defer posix.close(client_socket);

    // Set destination address (server address)
    const dest_addr = try net.Address.parseIp4("127.0.0.1", 4000);

    // Message to send
    const message = "Salut le Monde!";

    for (0..500) |i| {
        // Send the message to the server
        const bytes_sent = try posix.sendto(client_socket, message, 0, &dest_addr.any, dest_addr.getOsSockLen());
        std.debug.print("{d} - Sent {d} bytes to server\n", .{i, bytes_sent});
    }
}

