# AntiGravity Claude Proxy Bar

A macOS menu bar application for managing the AntiGravity Claude Proxy server.

## Prerequisites

You need to have the `antigravity-claude-proxy` npm package installed globally:

```bash
npm install -g antigravity-claude-proxy
```

Or you can use it via npx (the app will detect and use npx if the global package is not found).

## Building

### Requirements

- macOS 13.0 or later
- Xcode Command Line Tools
- Swift 5.9+

### Build the App

```bash
# Build and create the app bundle
make build

# Or run the build script directly
./create-app-bundle.sh
```

### Install

```bash
# Install to /Applications
make install
```

### Run

```bash
# Run the app
make run

# Or open directly
open "AntiGravity Claude Proxy.app"
```

## Features

- **Menu Bar Icon**: Shows server status (green bolt when running, gray when stopped)
- **Auto-start**: Server starts automatically when the app launches
- **Start/Stop Server**: Toggle the proxy server from the menu bar
- **Open WebUI**: Quick access to the web management interface
- **Settings**: Configure port, auto-start behavior, and launch at login
- **Notifications**: Get notified when the server starts or stops

## Menu Options

| Menu Item | Description |
|-----------|-------------|
| Status | Shows current server status and port |
| Start/Stop Server | Toggle the proxy server |
| Open WebUI | Opens the web interface in your browser |
| Settings... | Opens the settings window |
| Quit | Stops the server and exits the app |

## Settings

- **Port**: The port number for the proxy server (default: 8080)
- **Auto-start server**: Automatically start the server when the app launches
- **Launch at login**: Start the app when you log in to macOS

## Configuration

The app uses the same configuration as the `antigravity-claude-proxy` package:
- Config file: `~/.config/antigravity-proxy/config.json`
- Accounts: `~/.config/antigravity-proxy/accounts.json`

## Development

```bash
# Quick development build (debug mode)
make dev

# Clean build artifacts
make clean

# Test compilation only
make test-build
```

## Project Structure

```
antigravity-claude-proxy-bar/
├── src/
│   ├── Sources/
│   │   ├── main.swift           # App entry point
│   │   ├── AppDelegate.swift    # Menu bar and window management
│   │   ├── ServerManager.swift  # Server process control
│   │   ├── SettingsView.swift   # SwiftUI settings UI
│   │   └── Resources/
│   │       ├── icon-active.png  # Menu bar icon (running)
│   │       └── icon-inactive.png # Menu bar icon (stopped)
│   ├── Package.swift            # Swift Package Manager config
│   └── Info.plist               # macOS app metadata
├── create-app-bundle.sh         # Build script
├── Makefile                     # Build automation
└── README.md                    # This file
```

## License

MIT

## Author

[Irvan Fza](https://irvan.cc)

## Links

- [AntiGravity Claude Proxy](https://github.com/nicepkg/antigravity-claude-proxy) - The main proxy package
- [Report an Issue](https://github.com/IrvanFza/antigravity-claude-proxy-bar/issues)
