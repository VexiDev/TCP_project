# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### 0.0.1 (2025-03-06)


### Features

* added protocol.zig to test suite, removed main.zig and root.zig ([56d6474](https://github.com/VexiDev/TCP_project/commit/56d64745be22783f596579f52856d8ded5bbaf25))
* **client:** Added user input to allow for sending custom message to server ([f427fdd](https://github.com/VexiDev/TCP_project/commit/f427fddf4f74b8365cbcf62d38a1bd7dc158fe65))
* **client:** Build TCP Header and insert it before message into a packet ([0cd8b7a](https://github.com/VexiDev/TCP_project/commit/0cd8b7aa35bf1d659065950859e9db6d95dbf9fa))
* **client:** Created a basic client that sends data to the local server ([4806e6a](https://github.com/VexiDev/TCP_project/commit/4806e6ab743f7394a70f23e99f752607339ae5ac))
* **client:** removed python TCP client tester ([ce161cf](https://github.com/VexiDev/TCP_project/commit/ce161cf63ab0d116f5b1751eb88b09fce521e690))
* **protocol:** Created protcol.zig with basic header structure ([728d5fb](https://github.com/VexiDev/TCP_project/commit/728d5fb0fae7cee4198e60a98e3aef5e8e319491))
* **server:** implemented deserialization of TCP header from received packet ([4bc54f6](https://github.com/VexiDev/TCP_project/commit/4bc54f62026324c127c68d3e860e03a79ce6a28f))
* **server:** Parses received data as char and prints them ([4944c34](https://github.com/VexiDev/TCP_project/commit/4944c3448af639c4c95048cb470d907ad04e365a))
* **server:** Refactored to correctly run on IPPROTO and listen for received data ([31dde34](https://github.com/VexiDev/TCP_project/commit/31dde3460a25a28f6ea369167bf2d5ac5259433d))
* **server:** removed zig tcp implementation using net library ([a1d51a1](https://github.com/VexiDev/TCP_project/commit/a1d51a106b70dfd38c213330245c75c1ce2d4c6e))
* **tcp_impl:** created basic TCP header structure ([70e38d4](https://github.com/VexiDev/TCP_project/commit/70e38d435bf706087f71387beef06fa5f2937865))


### Bug Fixes

* **server:** Server byte buffer is now 1068 ([40be1e8](https://github.com/VexiDev/TCP_project/commit/40be1e83a795a00ac199108378899fdc9109efba))
