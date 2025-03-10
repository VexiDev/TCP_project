const std = @import("std");
const protocol = @import("./protocol.zig");
const posix = std.posix;
const net = std.net;

pub fn main() !void {
    const destaddr = try net.Address.parseIp4("127.0.0.1", 4000);
    
    const client_sock = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    defer posix.close(client_sock);
    
    try posix.connect(client_sock, &destaddr.any, destaddr.getOsSockLen());

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
        _ = try posix.send(client_sock, message, 0);
    }
}
