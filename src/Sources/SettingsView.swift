import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("serverPort") private var serverPort: Int = 8080
    @AppStorage("autoStart") private var autoStart: Bool = true
    @State private var launchAtLogin: Bool = false
    @State private var showingLogs: Bool = false
    @State private var portText: String = "8080"

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
                    serverSection
                    startupSection
                    actionsSection

                    if showingLogs {
                        logsSection
                    }
                }
                .padding(12)
            }

            Spacer()
                .frame(height: 6)

            // Footer
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("AntiGravity Claude Proxy \(appVersion)")
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
            .padding(.bottom, 12)

            // Hidden button for Command+Q keyboard shortcut
            Button("") {
                quitApp()
            }
            .keyboardShortcut("q", modifiers: .command)
            .hidden()
        }
        .frame(minWidth: 300, minHeight: 450)
        .onAppear {
            loadLaunchAtLoginState()
            portText = String(serverPort)
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
                Text(serverManager.isRunning ? "Running on port \(portText)" : "Stopped")
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
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Server Settings

    private var serverSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Server Settings")
                .font(.headline)

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

                Text("Default: 8080")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Restart the server and update ANTHROPIC_BASE_URL with new port.")
                .font(.caption)
                .foregroundColor(.secondary)
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

    // MARK: - Actions

    private func toggleServer() {
        if serverManager.isRunning {
            serverManager.stopServer()
            NotificationCenter.default.post(name: .showServerNotification,
                                            object: nil,
                                            userInfo: ["title": "Server Stopped", "body": "Antigravity Claude Proxy has been stopped"])
        } else {
            serverManager.startServer(port: serverPort) { success, error in
                DispatchQueue.main.async {
                    if success {
                        NotificationCenter.default.post(name: .showServerNotification,
                                                        object: nil,
                                                        userInfo: ["title": "Server Started", "body": "Antigravity Claude Proxy is running on port \(serverPort)"])
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
