const std = @import("std");
const protocol = @import("./netstack.zig");
const net = std.net;
const mem = std.mem;
const posix = std.posix;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const proto = try protocol.StateMachine.init(allocator);

    //const dest = try net.Ip4Address.parse("127.0.0.1", 4000);
    const dest = try getIp4("server", 4000);
    var src = try getIp4("localhost", 4001);
    src = src;

    const dest_ip: [4]u8 = @bitCast(dest.sa.addr);
    std.debug.print("Dest: {any}\n", .{dest_ip});
    const src_ip: [4]u8 = @bitCast(src.sa.addr);
    std.debug.print("Src: {any}\n\n", .{src_ip});

    const socket: posix.socket_t = try protocol.socket();
    defer protocol.close(socket);

    //try protocol.bind(socket, src);
    try proto.connect(socket, dest);

    const data = "Salut le Monde!";
    var msg: []const u8 = data[0..];

    for (0..100) |_| {
        //const bytes = try proto.sendto(socket, &msg, src, dest);
        const bytes = try proto.send(socket, &msg);

        const ip_bytes: [4]u8 = @bitCast(dest.sa.addr);
        std.debug.print("Sent {d} bytes to {any}\n", .{ bytes, ip_bytes });
        std.time.sleep(5 * 1_000_000_000);
    }
}

fn getIp4(name: []const u8, port: u16) !net.Ip4Address {
    const address_list = try std.net.getAddressList(std.heap.page_allocator, name, port);
    defer address_list.deinit();

    const destaddr = address_list.addrs[0].in;
    const ip_bytes: [4]u8 = @bitCast(destaddr.sa.addr); // convert u32 to [4]u8
    const parsed_port = std.mem.bigToNative(u16, destaddr.sa.port); // network byte order → native

    return net.Ip4Address.init(ip_bytes, parsed_port);
}
