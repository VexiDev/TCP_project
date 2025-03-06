const std = @import("std");
const print = std.debug.print;

// Header
// - Is 5 u32 segments of 4 u8 per segment for a total of 24 u8

pub const Header = struct {
    srcport: u16,
    destport: u16,

    pub fn serialize(self: *Header, bufr: []u8) ![]const u8 {
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

test "Test protocol" {
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
