# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-02-13

### Added

- Initial release of ark-playwright-mcp
- Dockerfile wrapping Microsoft's official Playwright MCP image
- Complete Helm chart with customizable values
- MCPServer CRD for ARK integration
- Support for 19+ browser automation tools:
  - Navigation: browser_navigate, browser_go_back, browser_resize, browser_close, browser_tabs
  - Interaction: browser_click, browser_type, browser_fill, browser_select_option, browser_drag_and_drop, browser_hover, browser_press_key, browser_upload_file
  - Inspection: browser_snapshot, browser_screenshot, browser_network_requests, browser_console_messages
  - Advanced: browser_evaluate, browser_handle_dialog, browser_run_code
- Vision, PDF, and Testing capabilities enabled by default
- Persistent volume support for artifacts (screenshots, traces, videos)
- Resource limits and security context configuration
- Health check and readiness probes
- One-line installation script (scripts/install.sh)
- Makefile with build, test, deploy targets
- Sample ARK resources (agent and query examples)
- Comprehensive documentation:
  - README.md with quick start
  - Architecture documentation
  - Configuration guide
  - Tools reference
  - Troubleshooting guide

### Configuration Options

- Headless/headed mode
- Browser selection (Chromium, Firefox, WebKit)
- Timeout configuration (action, navigation)
- Console logging levels
- Network security (allowed/blocked origins)
- Snapshot modes (incremental, full, none)
- Trace and video recording
- Advanced capabilities (vision, PDF, testing)

### Infrastructure

- CI/CD workflows (planned)
- E2E test suite (planned)
- Multi-architecture Docker builds (amd64, arm64)
- OCI registry publishing (GHCR)

### Known Limitations

- Single replica deployment (no horizontal scaling yet)
- Local storage only (no S3/object storage integration)
- No built-in metrics/monitoring dashboard
- Requires ARK to be pre-installed

### Security

- Non-root container execution
- Dropped Linux capabilities
- Sandboxed browser execution
- Network origin filtering support

[Unreleased]: https://github.com/skokaina/ark-playwright-mcp/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/skokaina/ark-playwright-mcp/releases/tag/v0.1.0
