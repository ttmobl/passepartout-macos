//
//  PreferencesViewController.swift
//  Passepartout-macOS
//
//  Created by Davide De Rosa on 5/31/19.
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

class PreferencesViewController: NSViewController {
    @IBOutlet private weak var tabView: NSTabView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = L10n.App.Preferences.title(GroupConstants.App.name)
        let labels = [
            L10n.App.Preferences.Sections.General.header,
            L10n.Core.Service.Sections.Trusted.header,
            L10n.Core.Service.Sections.Diagnostics.header
        ]
        tabView.tabViewItems.enumerated().forEach {
            $1.label = labels[$0]
        }
    }
}
