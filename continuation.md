# Repository handoff

This repository now has one active branch, `main`, and two documented Raspberry Pi targets:

- Pi 5 (`bcm2712`): active Build with Parallel-based build with MM8108 USB, `openmanetd`, Docker, and OpenTAKServer deployment.
- Pi 3B+ (`bcm2710`): archived OpenMANET image reference documented in [docs/rpi3b-plus.md](docs/rpi3b-plus.md).

The active Pi 5 build is complete and produces a verified SquashFS image under `bin/targets/bcm27xx/bcm2712/`. Build outputs, feeds, downloads, staging directories, and logs are intentionally untracked.

Do not use boot emulation as an acceptance criterion. The available QEMU release does not emulate a Raspberry Pi 5 machine; final boot and MM8108 radio validation require physical hardware.
