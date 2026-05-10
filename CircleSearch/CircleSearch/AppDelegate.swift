//
//  AppDelegate.swift
//  CircleSearch
//
//  Created by Liam McAuliffe on 5/9/26.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "magnifyingglass.circle", accessibilityDescription: "CircleSearch")
        }

        // Build the dropdown menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "CircleSearch is running", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
}