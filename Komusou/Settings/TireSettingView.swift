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
    @State var customTireSizeString: String
    @FocusState var isCustomTireSizeStringFieldFocused: Bool

    init(tireSize: Binding<TireSize>) {
        self._tireSize = tireSize

        if case .custom(let size) = tireSize.wrappedValue {
            var str = "\(size)"
            if str.count > 6 {
                str = String(str.prefix(6))
            }

            customTireSizeString = str
        } else {
            customTireSizeString = ""
        }

        if case .custom = tireSize.wrappedValue {
            isTireCustomSize = true
        } else {
            isTireCustomSize = false
        }
    }
    
    var body: some View {
        List {
            Section {
                Toggle("任意の値を使う", isOn: $isTireCustomSize)
                    .onChange(of: isTireCustomSize) { isTireCustomSize in
                        if !isTireCustomSize {
                            tireSize = .standard(.iso23_622)
                            customTireSizeString = ""
                        }
                    }
                if isTireCustomSize {
                    HStack {
                        // TODO: UserDefaultsから復元すると小数点一桁まで復元されるのを修正する
                        TextField("タイヤの直径 [mm]", text: $customTireSizeString)
                            .keyboardType(.decimalPad)
                            .focused($isCustomTireSizeStringFieldFocused)
                            .onChange(of: customTireSizeString) { [old = customTireSizeString] new in
                                if let size = Double(new),
                                   new.count <= 6 {
                                    tireSize = .custom(size)
                                } else if !new.isEmpty {
                                    customTireSizeString = old
                                }
                            }
                        Button {
                            customTireSizeString = ""
                            isCustomTireSizeStringFieldFocused = true
                        } label: {
                            Image(systemName: "multiply.circle.fill")
                                .foregroundColor(.init(UIColor.systemGray3))
                        }
                    }
                    .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
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
        TireSettingView(tireSize: .constant(.custom(200)))
            .previewLayout(.fixed(width: 400.0, height: 150.0))
            .preferredColorScheme(.dark)
        TireSettingView(tireSize: .constant(.custom(200)))
            .previewLayout(.fixed(width: 400.0, height: 150.0))
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
            let formatter = NumberFormatter()
            formatter.usesSignificantDigits = true
            formatter.maximumSignificantDigits = 6

            return formatter.string(from: circumference as NSNumber)!
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
