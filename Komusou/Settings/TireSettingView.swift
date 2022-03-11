//
//  TireSettingView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/09.
//

import SwiftUI
import Combine

struct TireSettingView: View {
    @Binding var tireSize: TireSize
    @State var isTireCustomSize: Bool
    @State var sizeString: String

    init(tireSize: Binding<TireSize>) {
        self._tireSize = tireSize

        if case .custom(let size) = tireSize.wrappedValue {
            sizeString = "\(size)"
        } else {
            sizeString = ""
        }

        if case .custom = tireSize.wrappedValue {
            isTireCustomSize = true
        } else {
            isTireCustomSize = false
        }
    }
    
    var body: some View {
        // TODO: いい感じにする
        List {
            Section {
                Toggle("任意の値を使う", isOn: $isTireCustomSize)
                if isTireCustomSize {
                    TextField("タイヤの直径 [mm]", text: $sizeString)
                        .keyboardType(.decimalPad)
                        .onChange(of: sizeString) { [old = sizeString] new in
                            if let size = Double(new) {
                                tireSize = .custom(size)
                            } else if !new.isEmpty {
                                sizeString = old
                            }
                        }
                }
            }

            if !isTireCustomSize {
                Section {
                    ForEach(StandardTireSize.allCases, id: \.label) { size in
                        Button {
                            tireSize = .standard(size)
                        } label: {
                            HStack {
                                Text(size.label)
                                    .foregroundColor(.init(UIColor.label))
                                Spacer()
                                if tireSize == .standard(size) {
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
