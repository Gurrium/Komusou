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

    @IBOutlet var speedLabel: UILabel!
    @IBOutlet var cadenceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        speedLabel.text = speedString(from: 0)
        cadenceLabel.text = cadenceString(from: 0)
    }

    func render(speed: Double) {
        speedLabel.text = speedString(from: speed)
    }

    func render(cadence: Double) {
        cadenceLabel.text = cadenceString(from: cadence)
    }

    private func speedString(from speed: Double) -> String {
        "\(Self.speedFormatter.string(from: .init(value: speed))!)[km/h]"
    }

    private func cadenceString(from cadence: Double) -> String {
        "\(Self.cadenceFormatter.string(from: .init(value: cadence))!)[rpm]" // km/hと合わせてr/mにしたい気持ちもあるが一般的な表記でないので…
    }
}
