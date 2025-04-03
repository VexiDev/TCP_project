const std = @import("std");
const protocol = @import("./netstack.zig");
const net = std.net;
const posix = std.posix;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const proto = try protocol.StateMachine.init(allocator);

    const src = try net.Ip4Address.parse("172.25.0.2", 4000);

    const socket: posix.socket_t = try protocol.socket();
    defer protocol.close(socket);

    try protocol.bind(socket, src);

    var arr: [55]u8 = undefined;
    var buffer: []u8 = &arr;

    var i: u16 = 0;
    while (true) : (i += 1) {
        const ip_bytes: [4]u8 = @bitCast(src.sa.addr); // convert u32 to [4]u8
        const port = std.mem.bigToNative(u16, src.sa.port); // network byte order → native
        std.debug.print("\nWaiting for bytes on {d}.{d}.{d}.{d}:{d}\n", .{ ip_bytes[0], ip_bytes[1], ip_bytes[2], ip_bytes[3], port });
        const bytes = try proto.recv(socket, &buffer);

        std.debug.print("{d} - Received {d} bytes:\n{s}\n", .{ i, bytes, buffer });
    }
}
