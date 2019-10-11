//
//  TrustedNetworksViewController.swift
//  Passepartout-macOS
//
//  Created by Davide De Rosa on 7/29/18.
//  Copyright (c) 2019 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import Cocoa
import PassepartoutCore

class TrustedNetworksViewController: NSViewController {
    private struct Columns {
        static let ssid = NSUserInterfaceItemIdentifier("SSID")

        static let trust = NSUserInterfaceItemIdentifier("Trust")
    }
    
    @IBOutlet private weak var labelTitle: NSTextField!

    @IBOutlet private weak var tableView: NSTableView!
    
    @IBOutlet private weak var buttonAdd: NSButton!

    @IBOutlet private weak var buttonRemove: NSButton!
    
    @IBOutlet private weak var checkDisableConnection: NSButton!
    
    @IBOutlet private weak var labelDisableConnectionDescription: NSTextField!

    private let service = TransientStore.shared.service

    private let model = TrustedNetworksModel()
    
    private lazy var vpn = GracefulVPN(service: service)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelTitle.stringValue = L10n.Core.Service.Sections.Trusted.header.asCaption
        buttonAdd.image = NSImage(named: NSImage.addTemplateName)
        buttonRemove.image = NSImage(named: NSImage.removeTemplateName)
        checkDisableConnection.title = L10n.Core.Service.Cells.TrustedPolicy.caption
        labelDisableConnectionDescription.stringValue = L10n.Core.Service.Sections.Trusted.footer

        checkDisableConnection.state = (service.preferences.trustPolicy == .disconnect) ? .on : .off
        model.delegate = self
        model.load(from: service.preferences)
        updateButtons()

        tableView.reloadData()
        for column in tableView.tableColumns {
            switch column.identifier {
            case Columns.ssid:
                column.title = "SSID"

            case Columns.trust:
                column.title = L10n.App.Trusted.Columns.Trust.title
                
            default:
                break
            }
        }
        if tableView.numberOfRows > 0 {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
    }
    
    // MARK: Actions
    
    @IBAction private func remove(_ sender: Any?) {
        let index = tableView.selectedRow
        guard index != -1 else {
            return
        }
        model.removeWifi(at: index)
    }
    
    @IBAction private func toggleRetainConnection(_ sender: Any?) {
        let isOn = (checkDisableConnection.state == .on)
        let completionHandler: () -> Void = {
            self.service.preferences.trustPolicy = isOn ? .disconnect : .ignore
            if self.vpn.isEnabled {
                self.vpn.reinstall(completionHandler: nil)
            }
        }
        guard isOn else {
            completionHandler()
            return
        }
        guard vpn.isEnabled else {
            completionHandler()
            return
        }
        let alert = Macros.warning(
            L10n.Core.Service.Sections.Trusted.header,
            L10n.Core.Service.Alerts.Trusted.WillDisconnectPolicy.message
        )
        alert.present(in: view.window, withOK: L10n.Core.Global.ok, cancel: L10n.Core.Global.cancel, handler: completionHandler, cancelHandler: {
            self.checkDisableConnection.state = .off
        })
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let addVC = segue.destinationController as? TrustedNetworksAddViewController {
            addVC.delegate = self
        }
    }

    // MARK: Helpers
    
    private func updateButtons() {
        buttonRemove.isEnabled = !model.sortedWifis.isEmpty && (tableView.selectedRow != -1)
    }
}

extension TrustedNetworksViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return model.sortedWifis.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < model.sortedWifis.count else { // XXX
            return nil
        }
        
        let wifi = model.sortedWifis[row]
        switch tableColumn?.identifier {
        case Columns.ssid:
            return wifi
            
        case Columns.trust:
            return model.isTrusted(wifi: wifi)
            
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard row < model.sortedWifis.count else { // XXX
            return
        }
        
        switch tableColumn?.identifier {
        case Columns.trust:
            guard let checkTrust = tableColumn?.dataCell(forRow: row) as? NSButtonCell else {
                fatalError("Expected a NSButtonCell for trust checkbox")
            }
            if checkTrust.state == .on {
                model.disableWifi(at: row)
            } else {
                model.enableWifi(at: row)
            }

        default:
            break
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }
}

extension TrustedNetworksViewController: TrustedNetworksModelDelegate {
    func trustedNetworksCouldDisconnect(_: TrustedNetworksModel) -> Bool {
        return (service.preferences.trustPolicy == .disconnect) && (vpn.status != .disconnected)
    }

    func trustedNetworksShouldConfirmDisconnection(_: TrustedNetworksModel, triggeredAt rowIndex: Int, completionHandler: @escaping () -> Void) {
        let alert = Macros.warning(
            L10n.Core.Service.Sections.Trusted.header,
            L10n.Core.Service.Alerts.Trusted.WillDisconnectTrusted.message
        )
        alert.present(in: view.window, withOK: L10n.Core.Global.ok, cancel: L10n.Core.Global.cancel, handler: completionHandler, cancelHandler: nil)
    }
    
    func trustedNetworks(_: TrustedNetworksModel, shouldInsertWifiAt rowIndex: Int) {
//        tableView.beginUpdates()
//        tableView.insertRows(at: IndexSet(integer: rowIndex), withAnimation: .slideDown)
//        tableView.endUpdates()
        tableView.reloadData()

        updateButtons()
    }
    
    func trustedNetworks(_: TrustedNetworksModel, shouldReloadWifiAt rowIndex: Int, isTrusted: Bool) {
        //
    }
    
    func trustedNetworks(_: TrustedNetworksModel, shouldDeleteWifiAt rowIndex: Int) {
//        tableView.beginUpdates()
//        tableView.removeRows(at: IndexSet(integer: rowIndex), withAnimation: .slideUp)
//        tableView.endUpdates()
        tableView.reloadData()

        updateButtons()
    }
    
    func trustedNetworksShouldReinstall(_: TrustedNetworksModel) {
        service.preferences.trustedWifis = model.trustedWifis
        if vpn.isEnabled {
            vpn.reinstall(completionHandler: nil)
        }
    }
}

extension TrustedNetworksViewController: TrustedNetworksAddViewControllerDelegate {
    func trustedController(_ trustedController: TrustedNetworksAddViewController, didEnterSSID ssid: String) {
        model.addWifi(ssid)
    }
}