const std = @import("std");
const protocol = @import("./netstack.zig");
const net = std.net;
const mem = std.mem;
const posix = std.posix;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const proto = try protocol.StateMachine.init(allocator);

    //const dest = try net.Ip4Address.parse("127.0.0.1", 4000);
    const address_list = try std.net.getAddressList(std.heap.page_allocator, "server", 4000);
    defer address_list.deinit();
    const destaddr = address_list.addrs[0].in;
    const ip_bytes: [4]u8 = @bitCast(destaddr.sa.addr); // convert u32 to [4]u8
    const port = std.mem.bigToNative(u16, destaddr.sa.port); // network byte order → native

    const dest = net.Ip4Address.init(ip_bytes, port);
    //const src = try net.Ip4Address.parse("127.0.0.1", 4001);

    const socket: posix.socket_t = try protocol.socket();
    defer protocol.close(socket);

    //try protocol.bind(socket, src);
    try proto.connect(socket, dest);

    const data = "Salut le Monde!";
    var msg: []const u8 = data[0..];

    for (0..100) |_| {
        //std.debug.print("Sending packet to {any}\n", .{ip_bytes});
        const bytes = try proto.send(socket, &msg);
        std.debug.print("Sent {d} bytes to {any}\n", .{bytes, ip_bytes});
        std.time.sleep(5 * 1_000_000_000);
    }
}
