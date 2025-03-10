# TCP Project

A TCP/IP stack written in Zig.

## Resources Used
1. [Beej's Guide to Network Programming](https://beej.us/guide/bgnet)
2. [Wikipedia](https://en.wikipedia.org)
    - [Transmission Control Protocol](https://en.wikipedia.org/wiki/Transmission_Control_Protocol)
3. [IETF Datatracker](https://datatracker.ietf.org)
    - [Internet Protocol (RFC 791)](https://datatracker.ietf.org/doc/rfc791/)
4. [Saminiir, "Let's code a TCP/IP stack"](https://www.saminiir.com/lets-code-tcp-ip-stack-1-ethernet-arp)

## IPv4 TCP/IP Stack Checklist
> *Subject to change as I learn more :D*

### IP Layer (Layer 3)
- [ ] Raw Packet Handling
- [ ] IP Header Construction
- [ ] Checksum Calculation
- [ ] Packet Fragmentation & Reassembly
- [ ] Routing & Addressing
- [ ] Error Handling

### TCP Layer (Layer 4)
- [ ] TCP Header Construction
- [ ] Three-Way Handshake (Connection Establishment)
- [ ] Connection State Management (TCP Finite State Machine)
- [ ] Send & Receive Data
- [ ] Acknowledgments & Retransmissions
- [ ] Flow Control (Sliding Window)
- [ ] Congestion Control (Algorithm TBD)
- [ ] Packet Reordering & Duplicate Handling
- [ ] Connection Teardown (Graceful Close)
- [ ] RST Handling (Abortive Close)
- [ ] Checksum Calculation
- [ ] Port Multiplexing

### Future Possilbe Features
- [ ] Manual Link Layer Handling
- [ ] Advanced Congestion Control
- [ ] Delayed ACKs & Nagle’s Algorithm
- [ ] Keep-Alive & Timeout Handling
- [ ] Support for TCP Options
- [ ] IPv6 Support
- [ ] Multithreading / Asynchronous Handling

