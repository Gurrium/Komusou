//
//  TireSettingView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/09.
//

import SwiftUI

struct TireSettingView: View {
    @Binding var tireSize: TireSize
    @State var isOn = false
    @State var size = ""
    
    var body: some View {
        // TODO: いい感じにする
        List {
            Section {
                Toggle("任意の値を使う", isOn: $isOn)
                if isOn {
                    // TODO: sanitize
                    TextField("タイヤの直径 [mm]", text: $size)
                        .keyboardType(.numberPad)
                }
            }

            if !isOn{
                Section {
                    ForEach(StandardTireSize.allCases, id: \.label) { size in
                        Button {
                            tireSize = .standard(size)
                        } label: {
                            HStack {
                                Text(size.label)
                                    .foregroundColor(.init(UIColor.label))
                                Spacer()
                                if tireSize == size {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TireSettingView_Previews: PreviewProvider {
    static var previews: some View {
        TireSettingView(tireSize: .constant(.standard(.iso25_622)))
    }
}

enum TireSize: Codable, RawRepresentable {
    init?(rawValue: String) {
        guard let d = Double(rawValue) else { return nil }

        if let standardTireSize = StandardTireSize(rawValue: d) {
            self = .standard(standardTireSize)
        } else {
            self = .custom(d)
        }
    }

    var rawValue: String { label }

    case standard(StandardTireSize)
    case custom(Double)

    var label: String {
        switch self {
        case .standard(let standardTireSize):
            return standardTireSize.label
        case .custom(let circumference):
            return "\(circumference)"
        }
    }

    var circumference: Double {
        switch self {
        case .standard(let standardTireSize):
            return standardTireSize.circumference
        case .custom(let circumference):
            return circumference
        }
    }
}

enum StandardTireSize: Double, CaseIterable {
    case iso23_622 = 2097
    case iso25_622 = 2105
    case iso28_622 = 2136

    var label: String {
        switch self {
        case .iso23_622:
            return "700x23"
        case .iso25_622:
            return "700x25"
        case .iso28_622:
            return "700x28"
        }
    }

    var circumference: Double {
        rawValue
    }
}
