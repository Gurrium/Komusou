//
//  InfoPanelView.swift
//  Komusou
//
//  Created by gurrium on 2022/05/29.
//

import SwiftUI

struct InfoPanelView: View {
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

    var speed: Double
    var cadence: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(Self.speedFormatter.string(from: .init(value: speed))!)[km/h]")
            Text("\(Self.cadenceFormatter.string(from: .init(value: cadence))!)[rpm]")
        }
        .foregroundColor(.white)
        .font(.headline)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.gray)
    }
}
