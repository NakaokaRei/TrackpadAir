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

//    private var statusItem: NSStatusItem!
//
//    func applicationDidFinishLaunching(_ notification: Notification) {
//        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//        let button = statusItem.button!
//        button.image = NSImage(size: NSSize(width: 18.0, height: 18.0))
//        let icon = NSImage(imageLiteralResourceName: "StatusBar-icon")
//        let iconView = IconView(icon, button.bounds.size)
//        button.addSubview(iconView)
//        button.action = #selector(showMenu)
//        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
//    }
//
//    @objc func showMenu(_ sender: NSStatusBarButton) {
//        guard let _ = NSApp.currentEvent else { return }
//        let menu = NSMenu()
//
//        menu.addItem(
//            withTitle: NSLocalizedString("Preference", comment: "Show preferences window"),
//            action: #selector(openPreferencesWindow),
//            keyEquivalent: ""
//        )
//        menu.addItem(.separator())
//        menu.addItem(
//            withTitle: NSLocalizedString("Quit", comment: "Quit app"),
//            action: #selector(terminate),
//            keyEquivalent: ""
//        )
//        statusItem.menu = menu
//        statusItem.button?.performClick(nil)
//        statusItem.menu = nil
//    }
//
//    @objc func terminate() {
//        NSApp.terminate(self)
//    }
//
//    @objc func openPreferencesWindow() {
//        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
//        NSApp.windows.forEach { if ($0.canBecomeMain) {$0.orderFrontRegardless() } }
//    }
}

