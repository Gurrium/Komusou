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
                    ForEach(TireSize.allCases, id: \.label) { size in
                        Button {
                            tireSize = size
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
        TireSettingView(tireSize: .constant(.iso25_622))
    }
}

enum TireSize: String, CaseIterable, Codable {
    case iso23_622
    case iso25_622
    case iso28_622

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
        switch self {
        case .iso23_622:
            return 2097
        case .iso25_622:
            return 2105
        case .iso28_622:
            return 2136
        }
    }
}
