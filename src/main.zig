const std = @import("std");
const posix = std.posix;
const os = std.os;

const AF_INET: u32 = 2;
const SOCK_RAW: u32 = 3;
const IPPROTO_TESTING: u32 = 253;

pub fn main() !void {
    
    // Creates a raw socket using an unused protocol
    const sockfd: posix.socket_t = try posix.socket(AF_INET, SOCK_RAW, IPPROTO_TESTING);
    defer posix.close(sockfd);

    // Set destination address (127.0.0.1)
    var addr = posix.sockaddr.in{ //
        .family = AF_INET,
        .port = std.mem.nativeToBig(u16, 0), 
        .addr = std.mem.nativeToBig(u32, 0x7F000001), // 127.0.0.1
        .zero = [_]u8{0} ** 8,
    };
    addr = addr;
    
    std.debug.print("Created raw socket with file descriptor: {d}\n", .{sockfd});

}
