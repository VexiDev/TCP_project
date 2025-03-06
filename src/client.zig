const std = @import("std");
const protocol = @import("./protocol.zig");
const posix = std.posix;
const net = std.net;

pub fn main() !void {
    const conn = try protocol.Connection.init( //
        protocol.Address{ .addr = "127.0.0.1", .port = 4001 }, // src addr
        protocol.Address{ .addr = "127.0.0.1", .port = 4000 }, // dest addr
    );
    defer conn.close();

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
        _ = try conn.send(message);
    }
}
