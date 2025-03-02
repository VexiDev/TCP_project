# TCP Project

A **VERY** basic and raw custom TCP implementation.

### Initial Steps: 
*subject to change as I learn more about this*

- [ ] Learn how to create raw sockets in Zig
- [ ] Define a very watered down TCP packet header
- [ ] Create a Server struct that:
    - [ ] will wait for any incoming connections
    - [ ] is able to complete the connection handshake
    - [ ] will then send some data (hello world probably)
- [ ] Create a Client struct that, using above tcp implementation,:
    - [ ] complete the connection handshake
    - [ ] receive some data
    - [ ] complete the close handshake
