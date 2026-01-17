import Foundation
import Combine

class ServerManager: ObservableObject {
    static let shared = ServerManager()

    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var logs: [String] = []
    @Published private(set) var isInstalled: Bool = true

    private let maxLogLines = 500

    private init() {
        _ = checkInstallation()
    }

    // MARK: - Server Control

    func startServer(port: Int, completion: @escaping (Bool, String?) -> Void) {
        // Check if already running
        if isRunning {
            completion(true, nil)
            return
        }

        // Kill any orphaned processes
        killOrphanedProcesses()

        // Find the npm command path
        guard let npmPath = findCommand("antigravity-claude-proxy") ?? findCommand("npx") else {
            completion(false, "Could not find antigravity-claude-proxy. Please install it with: npm install -g antigravity-claude-proxy")
            return
        }

        process = Process()
        outputPipe = Pipe()
        errorPipe = Pipe()

        // Determine how to run the command
        if npmPath.contains("antigravity-claude-proxy") {
            process?.executableURL = URL(fileURLWithPath: npmPath)
            process?.arguments = ["start"]
        } else {
            // Use npx as fallback
            process?.executableURL = URL(fileURLWithPath: npmPath)
            process?.arguments = ["antigravity-claude-proxy", "start"]
        }

        // Set environment with proper PATH for node
        var env = ProcessInfo.processInfo.environment
        env["PORT"] = String(port)

        // Add node's directory to PATH so #!/usr/bin/env node works
        if let nodePath = findCommand("node") {
            let nodeDir = (nodePath as NSString).deletingLastPathComponent
            let currentPath = env["PATH"] ?? "/usr/bin:/bin"
            env["PATH"] = "\(nodeDir):\(currentPath)"
        }

        process?.environment = env

        process?.standardOutput = outputPipe
        process?.standardError = errorPipe

        // Handle output
        setupOutputHandlers()

        // Handle termination
        process?.terminationHandler = { [weak self] proc in
            DispatchQueue.main.async {
                self?.isRunning = false
                if proc.terminationStatus != 0 {
                    self?.appendLog("Server exited with code \(proc.terminationStatus)")
                }
                NotificationCenter.default.post(name: .serverStatusChanged, object: nil)
            }
        }

        do {
            try process?.run()
            appendLog("Starting server on port \(port)...")

            // Wait a moment to check if it started successfully
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
                DispatchQueue.main.async {
                    if self?.process?.isRunning == true {
                        self?.isRunning = true
                        NotificationCenter.default.post(name: .serverStatusChanged, object: nil)
                        completion(true, nil)
                    } else {
                        self?.isRunning = false
                        let errorLogs = self?.logs.suffix(5).joined(separator: "\n") ?? "Unknown error"
                        completion(false, errorLogs)
                    }
                }
            }
        } catch {
            completion(false, error.localizedDescription)
        }
    }

    func stopServer() {
        guard let proc = process, proc.isRunning else {
            isRunning = false
            return
        }

        appendLog("Stopping server...")

        // Send SIGTERM first
        proc.terminate()

        // Wait briefly, then force kill if needed
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if proc.isRunning {
                proc.interrupt()
                DispatchQueue.main.async {
                    self?.appendLog("Force killed server")
                }
            }
        }

        process = nil
        outputPipe = nil
        errorPipe = nil

        DispatchQueue.main.async { [weak self] in
            self?.isRunning = false
            NotificationCenter.default.post(name: .serverStatusChanged, object: nil)
        }
    }

    func clearLogs() {
        DispatchQueue.main.async { [weak self] in
            self?.logs.removeAll()
        }
    }

    func checkInstallation() -> Bool {
        let installed = (findCommand("antigravity-claude-proxy") ?? findCommand("npx")) != nil
        DispatchQueue.main.async { [weak self] in
            self?.isInstalled = installed
        }
        return installed
    }

    // MARK: - Private Methods

    private func findCommand(_ name: String) -> String? {
        // Common paths to check (including Volta, fnm, asdf, pnpm, yarn)
        let home = ProcessInfo.processInfo.environment["HOME"] ?? ""
        let searchPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            "\(home)/.volta/bin",           // Volta
            "\(home)/.fnm/current/bin",     // fnm
            "\(home)/.asdf/shims",          // asdf
            "\(home)/.npm-global/bin",      // npm global
            "\(home)/.pnpm-global/bin",     // pnpm global
            "\(home)/.yarn/bin",            // Yarn global
            "\(home)/node_modules/.bin",    // Local node_modules
        ].filter { !$0.isEmpty }

        // Check direct path first
        for basePath in searchPaths {
            let fullPath = "\(basePath)/\(name)"
            if FileManager.default.isExecutableFile(atPath: fullPath) {
                return fullPath
            }
        }

        // Check NVM versions
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            let nvmPath = "\(home)/.nvm/versions/node"
            if let nodeVersions = try? FileManager.default.contentsOfDirectory(atPath: nvmPath) {
                for version in nodeVersions.sorted().reversed() {
                    let fullPath = "\(nvmPath)/\(version)/bin/\(name)"
                    if FileManager.default.isExecutableFile(atPath: fullPath) {
                        return fullPath
                    }
                }
            }
        }

        // Try using which
        let whichProcess = Process()
        let pipe = Pipe()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = [name]
        whichProcess.standardOutput = pipe
        whichProcess.standardError = FileHandle.nullDevice

        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {}

        return nil
    }

    private func killOrphanedProcesses() {
        let killProcess = Process()
        killProcess.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        killProcess.arguments = ["-f", "antigravity-claude-proxy"]
        killProcess.standardOutput = FileHandle.nullDevice
        killProcess.standardError = FileHandle.nullDevice

        try? killProcess.run()
        killProcess.waitUntilExit()
    }

    private func setupOutputHandlers() {
        outputPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.appendLog(str.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }

        errorPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.appendLog("[ERROR] \(str.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
        }
    }

    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logLine = "[\(timestamp)] \(message)"

        logs.append(logLine)

        // Trim buffer if too large
        if logs.count > maxLogLines {
            logs.removeFirst(logs.count - maxLogLines)
        }

        // Post notification for any listeners
        NotificationCenter.default.post(name: .serverLogUpdated, object: logLine)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let serverLogUpdated = Notification.Name("serverLogUpdated")
    static let serverStatusChanged = Notification.Name("serverStatusChanged")
    static let showServerNotification = Notification.Name("showServerNotification")
}
