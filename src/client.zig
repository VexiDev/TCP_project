const std = @import("std");
const protocol = @import("./protocol.zig");
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

        // Make and Serialize TCP header
        var hdr = protocol.Header{ .srcport = 4001, .destport = 4000 };
        var bufr: [24]u8 = undefined;
        _ = try hdr.serialize(&bufr);

        // Build final packet of header + message
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const packet = try std.fmt.allocPrint(allocator, "{s}{s}", .{ bufr, message});
        defer allocator.free(packet);

        // Send the message to the server
        const bytes_sent = try posix.sendto(client_socket, packet, 0, &dest_addr.any, dest_addr.getOsSockLen());
        std.debug.print("-> Sent {d} bytes to server\n", .{bytes_sent});
    }
}
