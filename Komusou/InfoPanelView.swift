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
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        return formatter
    }()

    private static let cadenceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        return formatter
    }()

    var speed: Double
    var cadence: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(Self.speedFormatter.string(from: .init(value: speed))!)[km/h]")
            Text("\(Self.cadenceFormatter.string(from: .init(value: cadence))!)[rpm]")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .foregroundColor(.white)
        .background(.gray)
        .font(.headline)
    }
}

struct InfoPanelView_Preview: PreviewProvider {
    static var previews: some View {
        InfoPanelView(speed: 60, cadence: 90)
    }
}
