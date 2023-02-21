//
//  AppDelegate.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Cocoa
import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.windows.forEach { $0.close() }
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let button = statusItem.button!
        button.image = NSImage(systemSymbolName: "rectangle.and.hand.point.up.left.fill", accessibilityDescription: nil)
        button.action = #selector(showPopover)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc func showPopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == NSEvent.EventType.rightMouseUp {
            let menu = NSMenu()

            menu.addItem(
                withTitle: NSLocalizedString("Preference", comment: "Show preferences window"),
                action: #selector(openPreferencesWindow),
                keyEquivalent: ""
            )
            menu.addItem(.separator())
            menu.addItem(
                withTitle: NSLocalizedString("Quit", comment: "Quit app"),
                action: #selector(terminate),
                keyEquivalent: ""
            )
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
            return
        }

        if popover == nil {
            let popover = NSPopover()
            popover.behavior = .transient
            popover.animates = false
            popover.contentViewController = NSHostingController(rootView: ContentView())
            self.popover = popover
        }
        popover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxY)
        popover?.contentViewController?.view.window?.makeKey()
    }

    @objc func terminate() {
        NSApp.terminate(self)
    }

    @objc func openPreferencesWindow() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        NSApp.windows.forEach { if ($0.canBecomeMain) {$0.orderFrontRegardless() } }
    }
}

