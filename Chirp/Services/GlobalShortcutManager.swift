//
//  GlobalShortcutManager.swift
//  Chirp
//
//  Created on 11/7/25.
//

import SwiftUI
import AppKit
import Carbon

class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private init() {}

    func setup() {
        // Register global keyboard shortcuts
        registerShortcut(
            keyCode: UInt32(kVK_F2), // F2 key
            modifiers: UInt32(cmdKey),
            action: { [weak self] in
                self?.handleStartFocus()
            }
        )
    }

    private func registerShortcut(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }

            let action = Unmanaged<ActionWrapper>.fromOpaque(userData).takeUnretainedValue().action
            DispatchQueue.main.async {
                action()
            }

            return noErr
        }

        let wrapper = ActionWrapper(action: action)
        let wrapperPtr = Unmanaged.passRetained(wrapper).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            wrapperPtr,
            &eventHandler
        )

        var hotKeyID = EventHotKeyID(signature: OSType(0x4348), id: 1)

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func handleStartFocus() {
        // Toggle focus session
        MenuBarManager.shared.startQuickSession(type: .deepWork)
    }

    func cleanup() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}

// Wrapper class to hold closure
private class ActionWrapper {
    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }
}
