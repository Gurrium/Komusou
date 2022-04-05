//
//  ControlPanelView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/21.
//

import UIKit

final class ControlPanelView: UIView {
    private static let speedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 3
        formatter.maximumSignificantDigits = 3

        return formatter
    }()

    private static let cadenceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 2
        formatter.maximumSignificantDigits = 3

        return formatter
    }()

//    @IBOutlet weak var speedPanel: UIView!
    @IBOutlet var speedLabel: UILabel!
//    @IBOutlet weak var cadencePanel: UIView!
    @IBOutlet var cadenceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        speedLabel.text = ""
        cadenceLabel.text = ""

//        speedPanel.clipsToBounds = true
//        speedPanel.layer.cornerRadius = 64
//        cadencePanel.clipsToBounds = true
//        cadencePanel.layer.cornerRadius = 64
    }

    func render(speed: Double, cadence: Double) {
        speedLabel.text = "\(Self.speedFormatter.string(from: .init(value: speed))!)[km/h]"
        cadenceLabel.text = "\(Self.cadenceFormatter.string(from: .init(value: cadence))!)[rpm]" // km/hと合わせてr/mにしたい気持ちもあるが一般的な表記でないので…
    }
}
