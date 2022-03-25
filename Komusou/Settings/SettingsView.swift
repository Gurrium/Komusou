//
//  SettingsView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/08.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: SettingsState

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("機材")) {
                    NavigationLink(destination: TireSettingView(tireSize: state.$tireSize)) {
                        HStack {
                            Text("タイヤ径")
                            Spacer()
                            Text(state.tireSize.label)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink(destination: SensorSettingView()) {
                        Text("センサー")
                    }
                }
                Section(header: Text("その他")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("0.1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("設定")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(state: .init())
    }
}

final class SettingsState: ObservableObject {
    @AppStorage("tireSize") var tireSize: TireSize = .standard(.iso25_622)
}
