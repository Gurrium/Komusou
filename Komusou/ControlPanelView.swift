//
//  ControlPanelView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/21.
//

import UIKit

final class ControlPanelView: UIView {
    @IBOutlet weak var speedPanel: UIView!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var cadencePanel: UIView!
    @IBOutlet weak var cadenceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        cadencePanel.clipsToBounds = true
        cadencePanel.layer.cornerRadius = 64
        speedPanel.clipsToBounds = true
        speedPanel.layer.cornerRadius = 64
    }
}
