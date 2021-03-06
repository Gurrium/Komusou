//
//  TireSettingView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/09.
//

import SwiftUI

struct TireSettingView: View {
    @Binding
    private var tireSize: TireSize
    @State
    private var isTireCustomSize: Bool
    @State
    private var customTireSizeString: String
    @FocusState
    private var isCustomTireSizeStringFieldFocused: Bool

    init(tireSize: Binding<TireSize>) {
        _tireSize = tireSize

        if case .custom(let circumference) = tireSize.wrappedValue {
            customTireSizeString = String(circumference)
            isTireCustomSize = true
        } else {
            customTireSizeString = ""
            isTireCustomSize = false
        }
    }

    var body: some View {
        List {
            Section {
                Toggle("任意の値を使う", isOn: $isTireCustomSize)
                    .onChange(of: isTireCustomSize) { isTireCustomSize in
                        if isTireCustomSize {
                            isCustomTireSizeStringFieldFocused = true
                        } else {
                            tireSize = .standard(.iso23_622)
                            customTireSizeString = ""
                        }
                    }
                if isTireCustomSize {
                    HStack {
                        TextField("タイヤの直径 [mm]", text: $customTireSizeString)
                            .keyboardType(.decimalPad)
                            .focused($isCustomTireSizeStringFieldFocused)
                            .onChange(of: customTireSizeString) { [old = customTireSizeString] new in
                                if let size = Int(new),
                                   new.count <= TireSize.significantDigits
                                {
                                    // 整数として解釈できる文字列
                                    tireSize = .custom(size)
                                } else if new.isEmpty {
                                    // 空文字列
                                    tireSize = .standard(.iso23_622)
                                } else {
                                    // 空文字列以外の不正な文字列
                                    customTireSizeString = old
                                }
                            }
                        if !customTireSizeString.isEmpty {
                            Button {
                                customTireSizeString = ""
                                isCustomTireSizeStringFieldFocused = true
                            } label: {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(Color(UIColor.systemGray3))
                            }
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
                                    .foregroundColor(.primary)
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
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
        TireSettingView(tireSize: .constant(.custom(200)))
            .previewLayout(.sizeThatFits)
    }
}

enum TireSize: RawRepresentable {
    static let significantDigits = 4

    init?(rawValue: Int) {
        if let standardTireSize = StandardTireSize(rawValue: rawValue) {
            self = .standard(standardTireSize)
        } else {
            self = .custom(rawValue)
        }
    }

    var rawValue: Int { circumference }

    case standard(StandardTireSize)
    case custom(Int)

    var label: String {
        switch self {
        case .standard(let standardTireSize):
            return standardTireSize.label
        case .custom(let circumference):
            return String(circumference)
        }
    }

    var circumference: Int {
        switch self {
        case .standard(let standardTireSize):
            return standardTireSize.circumference
        case .custom(let circumference):
            return circumference
        }
    }
}

enum StandardTireSize: Int, CaseIterable {
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

    var circumference: Int {
        rawValue
    }
}
