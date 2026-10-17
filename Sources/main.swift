import AppKit
import ApplicationServices

let device = "{\"VendorID\":11427,\"ProductID\":16401}"
let tag: Int64 = 0x444A4944
let root = NSHomeDirectory() + "/.local/share/dji-doubao-controller"

@discardableResult func run(_ executable: String, _ args: [String]) -> Int32 {
    let task = Process(); task.executableURL = URL(fileURLWithPath: executable); task.arguments = args
    task.standardOutput = FileHandle.nullDevice; task.standardError = FileHandle.nullDevice
    do { try task.run(); task.waitUntilExit(); return task.terminationStatus } catch { return -1 }
}
func map(_ destination: String) {
    run("/usr/bin/hidutil", ["property", "--matching", device, "--set", "{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":0xC000000E9,\"HIDKeyboardModifierMappingDst\":\(destination)}]}"])
}
func log(_ message: String) {
    // Operational events only: no dictated text, clipboard data, or typed characters.
    let path = root + "/events.log"
    if ((try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?.intValue ?? 0) > 262144 {
        try? FileManager.default.removeItem(atPath: path)
    }
    if !FileManager.default.fileExists(atPath: path) { FileManager.default.createFile(atPath: path, contents: nil) }
    if let handle = FileHandle(forWritingAtPath: path) {
        defer { try? handle.close() }; handle.seekToEndOfFile()
        handle.write(Data("\(ISO8601DateFormatter().string(from: Date())) \(message)\n".utf8))
    }
}
func key(_ code: CGKeyCode, option: Bool = false) {
    let source = CGEventSource(stateID: .privateState)
    guard let down = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
          let up = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false) else { return }
    if option { down.type = .flagsChanged; up.type = .flagsChanged; down.flags = .maskAlternate; up.flags = [] }
    down.setIntegerValueField(.eventSourceUserData, value: tag)
    up.setIntegerValueField(.eventSourceUserData, value: tag)
    down.post(tap: .cghidEventTap)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { up.post(tap: .cghidEventTap) }
}

enum Phase: String { case idle = "就绪", recording = "录音中", scheduled = "等待发送" }
final class Logic {
    var phase: Phase = .idle
    var generation = 0
    func press() -> Bool { // true = start, false = stop
        generation += 1
        if phase == .recording { phase = .scheduled; return false }
        phase = .recording; return true
    }
    func reset() { generation += 1; phase = .idle }
    func maySend(token: Int, sameApp: Bool) -> Bool {
        token == generation && phase == .scheduled && sameApp
    }
}

final class Controller: NSObject, NSApplicationDelegate {
    let logic = Logic()
    var item: NSStatusItem!
    var tap: CFMachPort?
    var buttonDown = false
    var targetPID: pid_t = 0
    var refresh: Timer?
    var permissionPoll: Timer?
    var activationObserver: NSObjectProtocol?
    var lastResult = "尚未启动"

    func applicationDidFinishLaunching(_ notification: Notification) {
        try? FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        NSApp.setActivationPolicy(.accessory)
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        func add(_ title: String, _ action: Selector) { let m = menu.addItem(withTitle: title, action: action, keyEquivalent: ""); m.target = self }
        add("启用／检查辅助功能权限", #selector(enable))
        menu.addItem(.separator())
        add("重置录音状态", #selector(resetMenu))
        add("退出并恢复原来的单击映射", #selector(quit))
        item.menu = menu
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
            guard let self, self.logic.phase == .scheduled,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            if app.processIdentifier != self.targetPID && !(app.bundleIdentifier ?? "").hasPrefix("com.bytedance.inputmethod.doubaoime") {
                self.reset("focus_switched_app")
            }
        }
        update(); enable()
        permissionPoll = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let self, self.tap == nil, AXIsProcessTrusted() else { return }
            self.enable()
        }
    }
    func update() {
        item.button?.title = tap == nil ? "Mic·待授权" : "Mic·" + logic.phase.rawValue
        let status: [String: Any] = ["version": "1.4.0", "active": tap != nil, "phase": logic.phase.rawValue, "mode": "fixed", "result": lastResult]
        if let data = try? JSONSerialization.data(withJSONObject: status, options: .sortedKeys) {
            try? data.write(to: URL(fileURLWithPath: root + "/status.json"), options: .atomic)
        }
    }
    @objc func enable() {
        guard tap == nil else { return }
        guard AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary) else {
            map("0x7000000E6")
            lastResult = "needs_accessibility"; update(); return
        }
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.rightMouseDown.rawValue)
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            return Unmanaged<Controller>.fromOpaque(context).takeUnretainedValue().event(type, event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap else { lastResult = "event_tap_unavailable"; log(lastResult); update(); return }
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0), .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        map("0x70000006D")
        refresh = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in map("0x70000006D") }
        lastResult = "enabled"; log(lastResult); update()
    }
    func event(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            buttonDown = false; reset("event_tap_interrupted")
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        if event.getIntegerValueField(.eventSourceUserData) == tag { return Unmanaged.passUnretained(event) }
        let code = event.getIntegerValueField(.keyboardEventKeycode)
        if (type == .keyDown || type == .keyUp) && code == 79 {
            if type == .keyUp { buttonDown = false }
            else if !buttonDown && event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                buttonDown = true
                // Let the event callback return immediately; perform work on the main queue.
                DispatchQueue.main.async { [weak self] in self?.button() }
            }
            return nil
        }
        if type == .keyDown && code == 53 { reset("escape_pressed") }
        if logic.phase == .scheduled {
            // Do NOT cancel on ordinary key events or AX element replacement: Doubao's
            // commit may synthesize Cmd+V/typing and web editors may replace AX objects.
            if type == .leftMouseDown || type == .rightMouseDown { reset("mouse_clicked") }
            else if type == .keyDown && (code == 36 || code == 76) { reset("enter_already_pressed") }
        }
        return Unmanaged.passUnretained(event)
    }
    func button() {
        let clickedAt = DispatchTime.now()
        if logic.press() {
            targetPID = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
            key(61, option: true)
            lastResult = "recording_started"; log(lastResult); update()
        } else {
            key(61, option: true)
            let token = logic.generation
            lastResult = "stop_enter_due_in_1s"; log(lastResult); update()
            DispatchQueue.main.asyncAfter(deadline: clickedAt + 1) { [weak self] in
                guard let self, token == self.logic.generation else { return }
                let sameApp = NSWorkspace.shared.frontmostApplication?.processIdentifier == self.targetPID
                if self.logic.maySend(token: token, sameApp: sameApp) {
                    key(36); self.reset("enter_posted")
                } else { self.reset("enter_skipped_different_app") }
            }
        }
    }
    func reset(_ reason: String) { logic.reset(); lastResult = reason; log(reason); update() }
    @objc func resetMenu() { reset("manual_reset") }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) {
        refresh?.invalidate(); permissionPoll?.invalidate(); logic.reset()
        if let observer = activationObserver { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        map("0x7000000E6")
    }
}

if CommandLine.arguments.contains("--self-test") {
    let l = Logic()
    assert(l.press() && l.phase == .recording)
    assert(!l.press() && l.phase == .scheduled)
    let token = l.generation
    assert(l.maySend(token: token, sameApp: true))
    assert(!l.maySend(token: token, sameApp: false))
    assert(l.press() && l.phase == .recording)
    assert(!l.maySend(token: token, sameApp: true))
    assert(!l.press()); let stopToken = l.generation
    l.reset(); assert(!l.maySend(token: stopToken, sameApp: true))
    assert(l.press()); assert(!l.press())
    print("PASS: single start/stop, send eligibility, focus change, new recording invalidates prior send, reset, repeated cycles")
} else {
    let controller = Controller()
    NSApplication.shared.delegate = controller
    NSApplication.shared.run()
}
