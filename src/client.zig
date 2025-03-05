const std = @import("std");
const posix = std.posix;
const net = std.net;

pub fn main() !void {

    // Create a raw socket with the same protocol as server (253)
    const client_socket = try posix.socket(posix.AF.INET, posix.SOCK.RAW, 253);
    defer posix.close(client_socket);

    // Set destination address (server address)
    const dest_addr = try net.Address.parseIp4("127.0.0.1", 4000);

    while (true) {
        const stdin = std.io.getStdIn().reader();
        const stdout = std.io.getStdOut().writer();

        try stdout.writeAll("Enter message to send: ");

        const bare_line = try stdin.readUntilDelimiterAlloc(
            std.heap.page_allocator,
            '\n',
            8192,
        );
        defer std.heap.page_allocator.free(bare_line);

        // Message to send
        const message = std.mem.trim(u8, bare_line, "\r");

        // Send the message to the server
        const bytes_sent = try posix.sendto(client_socket, message, 0, &dest_addr.any, dest_addr.getOsSockLen());
        std.debug.print("-> Sent {d} bytes to server\n", .{ bytes_sent });
    }
}
