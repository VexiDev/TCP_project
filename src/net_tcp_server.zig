const std = @import("std");
const net = std.net;

const Server = struct {
    address: [4]u8,
    port: u16,

    pub fn init(self: *Server, reuse_address: bool) !net.Server {
        const address = net.Address.initIp4(self.address, self.port);
        return try address.listen(.{ .reuse_address = reuse_address });
    }
};

pub fn main() !void {
    const address = net.Address.initIp4(.{ 127, 0, 0, 1 }, 4000);

    var server = try address.listen(.{ .reuse_address = true });

    std.debug.print("Server is listening on: {any}\n", .{address});
    while (true) {
        const client = try server.accept();
        const client_address = client.address;
        const stream = client.stream;

        // read buffer
        var buffer: [32]u8 = [_]u8{' '} ** 32;

        _ = try stream.read(&buffer);

        _ = try stream.write("Pong!");

        std.debug.print("Client connected with: {any}\n", .{client_address});
        std.debug.print("Request buffer is : {s}\n", .{buffer});
    }
}

