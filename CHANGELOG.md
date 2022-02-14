# Changelog

All notable changes to this project will be documented in this file.

## [v2.0.0-beta]() (2022-02-12)
* * *
[Full Changelog]()

### Summary
Currently tracks all changes made to the code for release 2.0.0.

### Added
- Support for LXD Cluster management
- Support for both container & virtual-machines via `lxd::instance`
- Tests for missing components
- `docs/` directory with more documentation & examples for components
- `examples/` directory now has examples for both single-node setup & cluster setup

### Changed
- `lxd::image` now supports retrieving official LXD images via `simplestreams`
- `lxd::config` now proplery sets & updates main lxd config values

### Removed
- Removed `lxd::container` as it was replaced by `lxd::instance`

### Fixed
- Project now works with PDK version `2.2.0`

### Known issues
- N/A

## Release 1.0.0
***
**Features**
Support for managing:
 * profiles
 * images
 * storage pools
 * containers

**Known Issues**
Only containers with architecture x86_64 are supported.
