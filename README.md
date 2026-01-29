# AntiGravity Claude Proxy Bar

<p align="center">
  <img src="images/icon.png" width="128" height="128" alt="AntiGravity Claude Proxy Bar Icon">
</p>

<p align="center">
<a href="https://github.com/IrvanFza/antigravity-claude-proxy-bar/blob/main/LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/License-MIT-28a745" style="max-width: 100%;"></a>
<a href="https://github.com/IrvanFza/antigravity-claude-proxy-bar"><img alt="Star this repo" src="https://img.shields.io/github/stars/IrvanFza/antigravity-claude-proxy-bar.svg?style=social&amp;label=Star%20this%20repo&amp;maxAge=60" style="max-width: 100%;"></a>
</p>

> **Help Wanted: Apple Developer ID Sponsorship**
>
> This project currently requires users to build the app from source because we don't have an Apple Developer ID certificate for code signing and notarization. Without proper signing, macOS Gatekeeper blocks downloaded apps.
>
> If you have an Apple Developer account and would like to help sponsor code signing for this project, please [open an issue](https://github.com/IrvanFza/antigravity-claude-proxy-bar/issues) or reach out! This would allow us to distribute pre-built binaries that work out of the box for all users.

**A beautiful native macOS menu bar application for managing the AntiGravity Claude Proxy server.**

This app is a convenient wrapper around [antigravity-claude-proxy](https://github.com/badrisnarayanan/antigravity-claude-proxy), providing an easy-to-use menu bar interface to start, stop, and configure your proxy server. No need to deal with terminal commands – just click and go!

Built with Swift and SwiftUI, it offers a native macOS experience.

<p align="center">
  <img width="325" height="268" alt="image" src="https://github.com/user-attachments/assets/e5f1d032-fadb-4b38-be2c-2ed79ee5eb65" />
</p>

<p align="center">
  <img width="562" height="794" alt="image" src="https://github.com/user-attachments/assets/170ba684-a51b-407f-a23d-8c6ef67e54d5" />
</p>

## Features

- 🎯 **Native macOS Experience** - Clean, native SwiftUI interface that feels right at home on macOS
- 🚀 **One-Click Server Management** - Start/stop the antigravity-claude-proxy server from your menu bar
- ⚡ **Installation Check** - Automatically detects if antigravity-claude-proxy is installed with helpful guidance if not
- 📋 **Installation Instructions** - Quick access to installation guide via menu bar or settings
- 🔄 **Auto-start** - Optionally start the server automatically when the app launches
- 🌐 **Quick WebUI Access** - Open the proxy web interface with one click
- ⚙️ **Configurable Port** - Set custom port for the proxy server (default: 8080)
- 🎛️ **Account Selection Strategy** - Choose between Hybrid, Sticky, or Round-Robin for multi-account load balancing
- 🔔 **Notifications** - Get notified when the server starts, stops, or encounters errors
- 🚦 **Status Indicator** - Menu bar icon shows server status (bolt icon: green when running, gray when stopped)
- 🎨 **Beautiful Icons** - Custom icons with template rendering for perfect menu bar integration
- 💾 **Launch at Login** - Start the app automatically when you log in to macOS

## Installation

### Prerequisites

**⚠️ Important:** This app requires the `antigravity-claude-proxy` npm package to be installed separately. The app will guide you through installation if it's not detected.

Install `antigravity-claude-proxy` globally:

```bash
npm install -g antigravity-claude-proxy
```

Or use it via npx (the app will detect and use npx if the global package is not found).

For more information, see the [antigravity-claude-proxy installation guide](https://github.com/badrisnarayanan/antigravity-claude-proxy).

### Build from Source

Since this app is not code-signed with an Apple Developer ID, you'll need to build it yourself. Don't worry - it's straightforward!

#### Requirements

- macOS 13.0 or later
- Xcode Command Line Tools (`xcode-select --install`)
- Swift 5.9+

#### Quick Start

```bash
# Clone the repository
git clone https://github.com/IrvanFza/antigravity-claude-proxy-bar.git
cd antigravity-claude-proxy-bar

# Build and install to /Applications
make install

# Launch the app
open "/Applications/AntiGravity Claude Proxy.app"
```

#### Alternative: Build Only

```bash
# Build the app bundle (creates "AntiGravity Claude Proxy.app" in current directory)
make build

# Run directly without installing
make run
```

## Usage

### First Launch

1. Launch AntiGravity Claude Proxy - you'll see a menu bar icon (bolt)
2. If antigravity-claude-proxy is not installed, you'll see a notification with instructions
3. Once installed, click the menu bar icon and select "Start Server" (or press ⌘S)
4. The icon will turn green when the server is running

### Menu Bar Options

<img src="images/menu-bar.png" width="300" alt="AntiGravity Claude Proxy Menu Bar">

| Menu Item                     | Shortcut | Description                                           |
| ----------------------------- | -------- | ----------------------------------------------------- |
| **Status**                    | -        | Shows current server status and port number           |
| **Start/Stop Server**         | ⌘S       | Toggle the proxy server on/off                        |
| **Open WebUI**                | ⌘O       | Opens the web interface in your default browser       |
| **Installation Instructions** | ⌘I       | Opens the antigravity-claude-proxy installation guide |
| **Settings...**               | ⌘,       | Opens the settings window                             |
| **Quit**                      | ⌘Q       | Stops the server and exits the app                    |

### Settings Window

<img src="images/setting-ui.png" width="300" alt="AntiGravity Claude Proxy Settings">

**Setup Information Section**

- Explains that this app is a wrapper for antigravity-claude-proxy
- Shows installation status with checkmark when installed
- Provides quick access to installation guide

**Server Settings**

- **Port**: Configure the port number for the proxy server (default: 8080)
- **Strategy**: Choose how requests are distributed across multiple accounts:
  - **Hybrid (Default)**: Smart distribution combining health, rate limiting, and quota awareness
  - **Sticky**: Stays on the same account to maximize cache hits, switches only when rate-limited
  - **Round-Robin**: Cycles through accounts sequentially for even load distribution
- Changes require server restart to take effect

**Startup Options**

- **Auto-start server**: Automatically start the server when the app launches
- **Launch at login**: Start the app automatically when you log in to macOS

**Actions**

- **Open WebUI**: Launch the web interface (only enabled when server is running)
- **Copy Server URL**: Copy `http://localhost:PORT` to clipboard
- **Show/Hide Logs**: Toggle real-time server logs display

### Server Logs

View real-time server output by clicking "Show Logs" in the settings window. Logs are color-coded:

- Normal output: Default text color
- Errors: Red text
- Maximum 500 lines kept in memory

## Configuration

The app uses the same configuration as the `antigravity-claude-proxy` package:

- Config file: `~/.config/antigravity-proxy/config.json`
- Accounts: `~/.config/antigravity-proxy/accounts.json`

Refer to the [antigravity-claude-proxy documentation](https://github.com/badrisnarayanan/antigravity-claude-proxy) for configuration options.

## Want to Contribute?

Contributions are welcome! Whether you're fixing bugs, adding features, improving documentation, or sharing ideas, your help is appreciated.

### Getting Started

1. **Fork the repository** and clone your fork
2. **Install dependencies** - You'll need:
   - macOS 13.0 or later
   - Xcode Command Line Tools
   - Swift 5.9+
   - `antigravity-claude-proxy` npm package for testing
3. **Make your changes** in a new branch
4. **Test your changes** thoroughly
5. **Submit a pull request** with a clear description of what you've changed and why

### Development Commands

```bash
# Quick development build (debug mode)
make dev

# Full release build
make build

# Install to /Applications for testing
make install

# Clean build artifacts
make clean

# Test compilation only
make test-build

# Run the app
make run
```

### Project Structure

```
antigravity-claude-proxy-bar/
├── src/
│   ├── Sources/
│   │   ├── main.swift             # App entry point
│   │   ├── AppDelegate.swift      # Menu bar and window management
│   │   ├── ServerManager.swift    # Server process control & installation check
│   │   ├── SettingsView.swift     # SwiftUI settings UI
│   │   ├── Constants.swift        # App constants (URLs, etc.)
│   │   └── Resources/
│   │       ├── AppIcon.icns       # App icon
│   │       ├── icon-active.png    # Menu bar icon (server running)
│   │       └── icon-inactive.png  # Menu bar icon (server stopped)
│   ├── Package.swift              # Swift Package Manager config
│   └── Info.plist                 # macOS app metadata
├── create-app-bundle.sh           # Build script
├── Makefile                       # Build automation
└── README.md                      # This file
```

### Key Components

- **AppDelegate**: Manages the menu bar item, settings window, and app lifecycle
- **ServerManager**: Controls the antigravity-claude-proxy process, checks installation status, and manages logs
- **SettingsView**: SwiftUI interface with native macOS design and real-time status updates
- **Constants**: Centralized constants including GitHub URLs for installation instructions

### Technical Details

**Installation Detection**

The app intelligently searches for `antigravity-claude-proxy` in multiple locations:

- Common system paths (`/usr/local/bin`, `/opt/homebrew/bin`, `/usr/bin`)
- Node version managers (Volta, fnm, asdf, NVM)
- Global package managers (npm, pnpm, yarn)
- Falls back to `npx` if the global package is not found

**Architecture**

- Built with Swift and SwiftUI for native macOS performance
- Uses Combine framework for reactive UI updates
- Process management via Foundation's Process API

### Reporting Issues

Found a bug or have a feature request? Please [open an issue](https://github.com/IrvanFza/antigravity-claude-proxy-bar/issues) with:

- Clear description of the issue or feature
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Your macOS version and app version
- Relevant logs or screenshots

## Roadmap

### Completed

- [x] Native macOS menu bar application with SwiftUI
- [x] One-click server start/stop with keyboard shortcuts
- [x] Real-time server logs with color-coded errors
- [x] Configurable port settings
- [x] Auto-start server on app launch
- [x] Launch at login support
- [x] Installation detection and user guidance
- [x] Quick WebUI access and URL copy
- [x] macOS notifications for server events
- [x] Support for multiple node version managers (Volta, fnm, asdf, NVM, npm, pnpm, yarn)
- [x] Sparkle framework for auto-updates
- [x] Node PATH fix for GUI app compatibility (v1.0.1)
- [x] VERSION file for centralized version management
- [x] Account selection strategy with Hybrid, Sticky, and Round-Robin options (v1.1.0)

### Planned

- [ ] (P0) **Apple Developer ID for code signing** - Allow users to download and run the app directly without building from source
- [ ] (P1) Add support for more node version managers (mise, proto, nodenv, n)
- [ ] (P1) Add port-in-use check with helpful error message
- [ ] (P1) Improve error handling and logging

See [TODO.md](TODO.md) for detailed implementation notes.

## Credits

This app is built as a native macOS wrapper around [antigravity-claude-proxy](https://github.com/badrisnarayanan/antigravity-claude-proxy), an excellent proxy server for Claude AI.

**Special thanks to:**

- **[antigravity-claude-proxy](https://github.com/badrisnarayanan/antigravity-claude-proxy)** - The core proxy server that powers this application
- **[VibeProxy](https://github.com/automazeio/vibeproxy)** - The inspiration for this project. The entire app structure, build setup, and code architecture were adapted from VibeProxy's excellent implementation.

Without these two excellent projects, this app wouldn't exist. Thank you to the maintainers and contributors of both projects!

## License

MIT License - see [LICENSE](LICENSE) file for details

---

Made with ⚡ by [IrvanFza](https://irvan.cc)
