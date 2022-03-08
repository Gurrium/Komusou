//
//  SettingsView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/08.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section(header: Text("機材")) {
                HStack {
                    Text("ホイール径")
                    Spacer()
                    Text("700x25c")
                        .foregroundColor(.init(UIColor.gray))
                    Image(systemName: "chevron.right")
                        .resizable()
                        .frame(width: 6.0, height: 12.0)
                        .foregroundColor(.init(UIColor.gray))
                }
            }
            Section(header: Text("その他")) {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("0.1")
                        .foregroundColor(.init(UIColor.gray))
                }
            }
        }
        .tint(Color(UIColor.label))
        .listStyle(.insetGrouped)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
