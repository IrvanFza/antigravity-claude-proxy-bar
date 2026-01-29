import SwiftUI
import ServiceManagement

enum AccountStrategy: String, CaseIterable {
    case hybrid = "hybrid"
    case sticky = "sticky"
    case roundRobin = "round-robin"

    var displayName: String {
        switch self {
            case .hybrid: return "Hybrid (Default)"
            case .sticky: return "Sticky (Cache-optimized)"
            case .roundRobin: return "Round-Robin (Load-balanced)"
        }
    }

    var description: String {
        switch self {
            case .hybrid: return "Hybrid: Smart distribution combining health, rate limiting, and quota awareness"
            case .sticky: return "Sticky: Stays on the same account for cache hits, switches when rate-limited"
            case .roundRobin: return "Round-Robin: Cycles through accounts sequentially for even distribution"
        }
    }
}

struct SettingsView: View {
    @AppStorage("serverPort") private var serverPort: Int = 8080
    @AppStorage("autoStart") private var autoStart: Bool = true
    @AppStorage("accountStrategy") private var accountStrategy: String = AccountStrategy.hybrid.rawValue
    @State private var launchAtLogin: Bool = false
    @State private var showingLogs: Bool = false
    @State private var portText: String = "8080"
    @State private var proxyVersionString: String?

    @ObservedObject private var serverManager = ServerManager.shared

    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "v\(version)"
        }
        return ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    installationSection
                    serverSection
                    startupSection
                    actionsSection

                    if showingLogs {
                        logsSection
                    }
                }
                .padding(12)
            }

            // Footer
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    if let proxyVersion = proxyVersionString {
                        Text("AntiGravity Claude Proxy v\(proxyVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("|")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Menu Bar \(appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Text("This proxy was made possible thanks to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Link("antigravity-claude-proxy", destination: URL(string: "https://github.com/nicepkg/antigravity-claude-proxy")!)
                        .font(.caption)
                        .underline()
                        .foregroundColor(.secondary)
                        .onHover { inside in
                            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                }

                HStack(spacing: 4) {
                    Link("Source Code", destination: URL(string: "https://github.com/IrvanFza/antigravity-claude-proxy-bar")!)
                        .font(.caption)
                        .onHover { inside in
                            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                    Text("|")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Link("Report an issue", destination: URL(string: "https://github.com/IrvanFza/antigravity-claude-proxy-bar/issues")!)
                        .font(.caption)
                        .onHover { inside in
                            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                }
            }

            // Hidden button for Command+Q keyboard shortcut
            Button("") {
                quitApp()
            }
            .keyboardShortcut("q", modifiers: .command)
            .hidden()
        }
        .frame(minWidth: 300, minHeight: 650)
        .onAppear {
            loadLaunchAtLoginState()
            portText = String(serverPort)
            proxyVersionString = serverManager.getProxyVersion()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: serverManager.isRunning ? "bolt.fill" : "bolt.slash")
                .font(.system(size: 24))
                .foregroundColor(serverManager.isRunning ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("AntiGravity Claude Proxy")
                    .font(.headline)
                Text(serverManager.isRunning ? "Running on port \(portText) with \(accountStrategy.prefix(1).uppercased() + accountStrategy.dropFirst()) strategy" : "Stopped")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: toggleServer) {
                Text(serverManager.isRunning ? "Stop" : "Start")
                    .frame(width: 60)
            }
            .buttonStyle(.borderedProminent)
            .tint(serverManager.isRunning ? .red : .green)
            .disabled(!serverManager.isInstalled)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Server Settings

    private var serverSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Server Settings")
                .font(.headline)

            Text("Restart the server to apply port or strategy changes.")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()
                .padding(.vertical, 4)

            Text("Set custom port for the proxy server. Default: 8080")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("Port:")
                    .frame(width: 80, alignment: .leading)

                TextField("Port", text: $portText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onChange(of: portText) { newValue in
                        // Only allow digits
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            portText = filtered
                        }
                        if let port = Int(filtered), port > 0, port <= 65535 {
                            serverPort = port
                        }
                    }
            }

            Divider()
                .padding(.vertical, 4)

            Text("Select how requests are distributed across multiple accounts.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline) {
                Text("Strategy:")
                    .frame(width: 80, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Picker("", selection: $accountStrategy) {
                        ForEach(AccountStrategy.allCases, id: \.rawValue) { strategy in
                            Text(strategy.displayName)
                                .tag(strategy.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.leading, -7)

                    if let selected = AccountStrategy(rawValue: accountStrategy) {
                        Text(selected.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Startup Settings

    private var startupSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Startup")
                .font(.headline)

            Toggle("Auto-start server when app launches", isOn: $autoStart)

            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    setLaunchAtLogin(enabled: newValue)
                }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Actions")
                .font(.headline)

            HStack(spacing: 8) {
                Button(action: openWebUI) {
                    Label("Open WebUI", systemImage: "globe")
                }
                .disabled(!serverManager.isRunning)

                Button(action: copyServerURL) {
                    Label("Copy Server URL", systemImage: "doc.on.doc")
                }
                .disabled(!serverManager.isRunning)

                Button(action: { showingLogs.toggle() }) {
                    Label(showingLogs ? "Hide Logs" : "Show Logs", systemImage: "terminal")
                }

                Spacer()
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Logs

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Logs")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    serverManager.clearLogs()
                }
                .buttonStyle(.borderless)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(serverManager.logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(log.contains("[ERROR]") ? .red : .primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 120)
            .padding(6)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(4)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Installation Section

    private var installationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(
                        serverManager.isInstalled ? "Setup Information" : "Installation Required",
                        systemImage: serverManager.isInstalled ? "info.circle" : "exclamationmark.triangle"
                    )
                    .font(.headline)

                    Spacer()

                    if serverManager.isInstalled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.headline)
                    }
                }
                Text("This application is a menu bar wrapper for the antigravity-claude-proxy package. The actual proxy server needs to be installed separately on your system.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !serverManager.isInstalled {
                    Text("⚠️ The antigravity-claude-proxy package is not currently installed. Please install it to enable server functionality.")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: {
                NSWorkspace.shared.open(AppConstants.installationGuideURL)
            }) {
                HStack {
                    Image(systemName: "book")
                    Text("View Installation Guide")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(serverManager.isInstalled
                    ? Color(NSColor.controlBackgroundColor)
                    : Color(NSColor.systemYellow).opacity(0.1))
        )
    }

    // MARK: - Actions

    private func toggleServer() {
        guard serverManager.isInstalled else {
            NotificationCenter.default.post(name: .showServerNotification,
                                            object: nil,
                                            userInfo: ["title": "Not Installed", "body": "Please install antigravity-claude-proxy first"])
            return
        }

        if serverManager.isRunning {
            serverManager.stopServer()
            NotificationCenter.default.post(name: .showServerNotification,
                                            object: nil,
                                            userInfo: ["title": "Server Stopped", "body": "Antigravity Claude Proxy has been stopped"])
        } else {
            serverManager.startServer(port: serverPort, strategy: accountStrategy) { success, error in
                DispatchQueue.main.async {
                    if success {
                        let strategyName = accountStrategy.prefix(1).uppercased() + accountStrategy.dropFirst()
                        NotificationCenter.default.post(name: .showServerNotification,
                                                        object: nil,
                                                        userInfo: ["title": "Server Started", "body": "Running on port \(serverPort) with \(strategyName) strategy"])
                    } else {
                        NotificationCenter.default.post(name: .showServerNotification,
                                                        object: nil,
                                                        userInfo: ["title": "Server Failed", "body": error ?? "Unknown error"])
                    }
                }
            }
        }
    }

    private func openWebUI() {
        if let url = URL(string: "http://localhost:\(serverPort)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func copyServerURL() {
        let url = "http://localhost:\(serverPort)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
    }

    // MARK: - Launch at Login

    private func loadLaunchAtLoginState() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }

    // MARK: - App Control

    private func quitApp() {
        serverManager.stopServer()
        NSApp.terminate(nil)
    }
}
