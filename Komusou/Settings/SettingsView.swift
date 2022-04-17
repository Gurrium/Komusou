//
//  SettingsView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/08.
//

import SwiftUI

// TODO: kTireSizeKeyの定義はここが適切？
let kTireSizeKey = "tireSize"
struct SettingsView: View {
    @AppStorage(kTireSizeKey) var tireSize: TireSize = .standard(.iso25_622)

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("機材")) {
                    NavigationLink(destination: TireSettingView(tireSize: $tireSize)) {
                        HStack {
                            Text("タイヤ径")
                            Spacer()
                            Text(tireSize.label)
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
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)
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
        SettingsView()
    }
}
