# TODO

## High Priority

### 1. Add missing node version manager paths
**File:** `src/Sources/ServerManager.swift` (lines 156-166)

**Issue:** Some popular node version managers are not supported, causing the app to fail to find node/npm for users of these tools.

**Missing paths to add:**
```swift
"\(home)/.local/share/mise/shims",  // mise (formerly rtx)
"\(home)/.proto/shims",              // proto
"\(home)/.nodenv/shims",             // nodenv
"/usr/local/n/versions/node",        // n (needs version enumeration like NVM)
```

**For `n` version manager**, add similar logic to NVM:
```swift
// Check n versions
let nPath = "/usr/local/n/versions/node"
if let nodeVersions = try? FileManager.default.contentsOfDirectory(atPath: nPath) {
    for version in nodeVersions.sorted().reversed() {
        let fullPath = "\(nPath)/\(version)/bin/\(name)"
        if FileManager.default.isExecutableFile(atPath: fullPath) {
            return fullPath
        }
    }
}
```

---

### 2. Add port-in-use check
**File:** `src/Sources/ServerManager.swift` (in `startServer` function)

**Issue:** If port 8080 (or custom port) is already in use by another process, the server fails with an unclear error message.

**Solution:** Check if port is available before starting:
```swift
private func isPortAvailable(_ port: Int) -> Bool {
    let socket = socket(AF_INET, SOCK_STREAM, 0)
    guard socket >= 0 else { return false }
    defer { close(socket) }

    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = in_port_t(port).bigEndian
    addr.sin_addr.s_addr = INADDR_ANY

    let result = withUnsafePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            bind(socket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    return result == 0
}
```

Then in `startServer`:
```swift
guard isPortAvailable(port) else {
    completion(false, "Port \(port) is already in use. Please choose a different port in Settings.")
    return
}
```

---

## Medium Priority

### 3. Remove useless `which` command fallback
**File:** `src/Sources/ServerManager.swift` (lines 190-207)

**Issue:** The `which` command runs in the same limited GUI environment, so it won't find binaries that aren't in the minimal PATH. It's effectively useless for GUI apps.

**Options:**
- Remove it entirely (recommended - it gives false hope and wastes cycles)
- Or set a proper PATH before running `which`

---

### 4. Add error handling for NVM directory
**File:** `src/Sources/ServerManager.swift` (line 180)

**Issue:** If `~/.nvm/versions/node` exists but is unreadable (permissions issue), it silently fails.

**Solution:** Add logging for debugging:
```swift
if let nodeVersions = try? FileManager.default.contentsOfDirectory(atPath: nvmPath) {
    // existing code
} else if FileManager.default.fileExists(atPath: nvmPath) {
    // Directory exists but couldn't be read - log for debugging
    print("Warning: NVM directory exists but couldn't be read: \(nvmPath)")
}
```

---

## Low Priority

### 5. Clean up race condition on stop
**File:** `src/Sources/ServerManager.swift` (lines 127-129)

**Issue:** Setting `process = nil` immediately after `terminate()` while the force-kill dispatch block still references the old `proc`. Currently works because `proc` is captured, but could be cleaner.

**Solution:** Move `process = nil` after the force-kill dispatch or use a more structured approach:
```swift
func stopServer() {
    guard let proc = process, proc.isRunning else {
        isRunning = false
        return
    }

    appendLog("Stopping server...")
    proc.terminate()

    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
        if proc.isRunning {
            proc.interrupt()
            DispatchQueue.main.async {
                self?.appendLog("Force killed server")
            }
        }
        // Clean up after force kill attempt
        DispatchQueue.main.async {
            self?.process = nil
            self?.outputPipe = nil
            self?.errorPipe = nil
        }
    }

    DispatchQueue.main.async { [weak self] in
        self?.isRunning = false
        NotificationCenter.default.post(name: .serverStatusChanged, object: nil)
    }
}
```
