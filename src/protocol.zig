const std = @import("std");
const net = std.net;
const posix = std.posix;
const print = std.debug.print;

// Header
// - Is 5 u32 segments of 4 u8 per segment for a total of 24 u8

pub const Status = union(enum) { LISTEN, SYN_SENT, SYN_RECEIVED, ESTABLISHED, FIN_WAIT_1, FIN_WAIT_2, CLOSE_WAIT, CLOSING, LAST_ACK, TIME_WAIT, CLOSED };

pub const Address = struct { addr: []const u8, port: u16 };

pub const Connection = struct {
    socket: posix.socket_t,
    status: Status = Status.CLOSED,
    header: Header,
    srcaddr: net.Address,
    destaddr: net.Address,

    pub fn init(src: Address, dest: Address) !Connection {
        // parse addresses
        const srcaddr = try net.Address.parseIp4(src.addr, src.port);
        const destaddr = try net.Address.parseIp4(dest.addr, dest.port);

        // create header
        const header = Header{ .srcport = src.port, .destport = dest.port };

        // open socket
        const socket = try posix.socket(posix.AF.INET, posix.SOCK.RAW, 253);

        return .{
            .socket = socket,
            .header = header,
            .srcaddr = srcaddr,
            .destaddr = destaddr,
        };
    }

    pub fn send(self: *const Connection, data: []const u8) !usize {
        // serialize header into []const u8
        var bufr: [24]u8 = undefined;
        _ = try self.header.serialize(&bufr);

        // prepend tcp header in front of data
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const packet = try std.fmt.allocPrint(allocator, "{s}{s}", .{ bufr, data });
        defer allocator.free(packet);
        const bytes_sent = try posix.sendto(self.socket, packet, 0, &self.destaddr.any, self.destaddr.getOsSockLen());
        std.debug.print("-> Sent {d} bytes to server\n", .{bytes_sent});
        return bytes_sent;
    }

    pub fn close(self: *const Connection) void {
        posix.close(self.socket);
    }
};

pub const Header = struct {
    srcport: u16,
    destport: u16,

    pub fn serialize(self: *const Header, bufr: []u8) ![]const u8 {
        if (bufr.len < 24) return error.BufferTooSmall;
        // srcport - 2 bytes
        bufr[0] = @truncate(self.srcport >> 8);
        bufr[1] = @truncate(self.srcport);
        // desport - 2 bytes
        bufr[2] = @truncate(self.destport >> 8);
        bufr[3] = @truncate(self.destport);

        return bufr[0..];
    }

    pub fn deserialize(bufr: []u8) !Header {
        if (bufr.len < 24) return error.BufferTooSmall;

        // srcport - 2 bytes
        var srcport: u16 = @as(u16, bufr[0]);
        srcport = srcport << 8;
        srcport = srcport | @as(u16, bufr[1]);
        // desport - 2 bytes
        var destport: u16 = @as(u16, bufr[2]);
        destport = destport << 8;
        destport = destport | @as(u16, bufr[3]);

        return Header{ .srcport = srcport, .destport = destport };
    }
};

test "Test header" {
    var h = Header{ .srcport = 4001, .destport = 4000 };

    var buf: [24]u8 = undefined;
    const serialized = try h.serialize(&buf);

    const expected: [4]u8 = [_]u8{ 15, 161, 15, 160 };
    try std.testing.expectEqualSlices(u8, serialized[0..4], expected[0..]);

    const deserialized = try Header.deserialize(&buf);

    try std.testing.expect(@TypeOf(deserialized) == Header);
}

// TODO: abstract these:
// - Protocol Send
// - Protocol Receive
