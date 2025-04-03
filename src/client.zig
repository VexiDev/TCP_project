const std = @import("std");
const protocol = @import("./protocol.zig");
const posix = std.posix;
const net = std.net;

pub fn main() !void {
    //const destaddr = try net.Address.resolveIp("127.0.0.1", 4000);
    const address_list = try std.net.getAddressList(std.heap.page_allocator, "socket-server", 4000);
    defer address_list.deinit();
    const destaddr = address_list.addrs[0];

    const client_sock = try posix.socket(posix.AF.INET, posix.SOCK.STREAM, 0);
    defer posix.close(client_sock);

    try posix.connect(client_sock, &destaddr.any, destaddr.getOsSockLen());

    while (true) {
        //const stdin = std.io.getStdIn().reader();
        //
        //const stdout = std.io.getStdOut().writer();

        //try stdout.writeAll("Enter message to send: ");

        //const bare_line = try stdin.readUntilDelimiterAlloc(
        //    std.heap.page_allocator,
        //    '\n',
        //    8192,
        //);
        //defer std.heap.page_allocator.free(bare_line);

        //// Message to send
        //const message = std.mem.trim(u8, bare_line, "\r");
        
        const message = "Salut le Monde!";

        // Send the message to the server
        _ = try posix.send(client_sock, message, 0);

        std.time.sleep(3 * 1_000_000_000);
    }
}
