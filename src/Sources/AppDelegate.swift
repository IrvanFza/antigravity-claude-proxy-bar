import AppKit
import SwiftUI
import UserNotifications
import Combine
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var startStopMenuItem: NSMenuItem!
    private var openWebUIMenuItem: NSMenuItem!
    private var settingsWindow: NSWindow?

    private let serverManager = ServerManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let updaterController: SPUStandardUpdaterController

    // MARK: - Initialization

    override init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        super.init()
    }

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupNotifications()
        setupMenuBar()
        setupObservers()

        // Check installation status at startup
        let isInstalled = serverManager.checkInstallation()
        if !isInstalled {
            showNotification(
                title: "Installation Required",
                body: "antigravity-claude-proxy is not installed. Please install it to use this application."
            )
        }

        // Auto-start server if enabled and installed
        let autoStart = UserDefaults.standard.object(forKey: "autoStart") as? Bool ?? true
        if autoStart && isInstalled {
            startServer()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        serverManager.stopServer()
    }

    // MARK: - Notification Setup

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Observers

    private func setupObservers() {
        // Observe installation status
        serverManager.$isInstalled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isInstalled in
                self?.updateMenuBar(installed: isInstalled)
            }
            .store(in: &cancellables)

        // Observe server status changes
        serverManager.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRunning in
                let port = UserDefaults.standard.integer(forKey: "serverPort")
                let effectivePort = port > 0 ? port : 8080
                self?.updateStatus(running: isRunning, port: effectivePort)
            }
            .store(in: &cancellables)

        // Observe notification requests from SettingsView
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowNotification(_:)),
            name: .showServerNotification,
            object: nil
        )
    }

    @objc private func handleShowNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let title = userInfo["title"] as? String,
              let body = userInfo["body"] as? String else { return }
        showNotification(title: title, body: body)
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateMenuBarIcon(running: false)
            button.toolTip = "AntiGravity Claude Proxy"
        }

        let menu = NSMenu()

        // Status
        statusMenuItem = NSMenuItem(title: "Server: Stopped", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Start/Stop
        startStopMenuItem = NSMenuItem(title: "Start Server", action: #selector(toggleServer), keyEquivalent: "s")
        startStopMenuItem.target = self
        menu.addItem(startStopMenuItem)

        // Open WebUI
        openWebUIMenuItem = NSMenuItem(title: "Open WebUI", action: #selector(openWebUI), keyEquivalent: "o")
        openWebUIMenuItem.target = self
        openWebUIMenuItem.isEnabled = false
        menu.addItem(openWebUIMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Installation Instructions
        let installationItem = NSMenuItem(title: "Installation Instructions", action: #selector(openInstallationGuide), keyEquivalent: "i")
        installationItem.target = self
        menu.addItem(installationItem)

        // Check for Updates
        let checkForUpdatesItem = NSMenuItem(title: "Check for Updates", action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)), keyEquivalent: "u")
        checkForUpdatesItem.target = updaterController
        menu.addItem(checkForUpdatesItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateMenuBarIcon(running: Bool) {
        guard let button = statusItem.button else { return }

        // Try to load custom icons from Resources
        let iconName = running ? "icon-active" : "icon-inactive"
        if let iconPath = Bundle.main.path(forResource: iconName, ofType: "png", inDirectory: "Resources"),
           let image = NSImage(contentsOfFile: iconPath) {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            button.image = image
        } else {
            // Fallback to SF Symbols
            let symbolName = running ? "bolt.fill" : "bolt.slash"
            if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Server Status") {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
            }
        }
    }

    private func updateStatus(running: Bool, port: Int = 8080) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.updateMenuBarIcon(running: running)

            if running {
                self.statusMenuItem.title = "Server: Running (port \(port))"
                self.startStopMenuItem.title = "Stop Server"
                self.openWebUIMenuItem.isEnabled = true
            } else {
                self.statusMenuItem.title = "Server: Stopped"
                self.startStopMenuItem.title = "Start Server"
                self.openWebUIMenuItem.isEnabled = false
            }
        }
    }

    private func updateMenuBar(installed: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.startStopMenuItem.isEnabled = installed

            if !installed {
                self.startStopMenuItem.title = "Start Server (Not Installed)"
            } else {
                self.startStopMenuItem.title = self.serverManager.isRunning ? "Stop Server" : "Start Server"
            }
        }
    }

    // MARK: - Server Control

    private func startServer() {
        let port = UserDefaults.standard.integer(forKey: "serverPort")
        let effectivePort = port > 0 ? port : 8080

        serverManager.startServer(port: effectivePort) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.showNotification(title: "Server Started", body: "AntiGravity Claude Proxy is running on port \(effectivePort)")
                } else {
                    self?.showNotification(title: "Server Failed", body: error ?? "Unknown error")
                }
            }
        }
    }

    private func stopServer() {
        serverManager.stopServer()
        showNotification(title: "Server Stopped", body: "AntiGravity Claude Proxy has been stopped")
    }

    @objc private func toggleServer() {
        guard serverManager.isInstalled else {
            showNotification(
                title: "Not Installed",
                body: "Please install antigravity-claude-proxy first. See Installation Instructions for help."
            )
            return
        }

        if serverManager.isRunning {
            stopServer()
        } else {
            startServer()
        }
    }

    // MARK: - Actions

    @objc private func openWebUI() {
        let port = UserDefaults.standard.integer(forKey: "serverPort")
        let effectivePort = port > 0 ? port : 8080

        if let url = URL(string: "http://localhost:\(effectivePort)") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openInstallationGuide() {
        NSWorkspace.shared.open(AppConstants.installationGuideURL)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "AntiGravity Claude Proxy Settings"
            settingsWindow?.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            settingsWindow?.setContentSize(NSSize(width: 450, height: 350))
            settingsWindow?.center()
            settingsWindow?.isReleasedWhenClosed = false
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        serverManager.stopServer()
        NSApp.terminate(nil)
    }

    // MARK: - Notifications

    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
}
