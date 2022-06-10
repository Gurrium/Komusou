//
//  View+AlertForEnablingBluetooth.swift
//  Komusou
//
//  Created by gurrium on 2022/06/10.
//

import SwiftUI
import UIKit

extension View {
    func alert(isBluetoothDisabled: Binding<Bool>) -> some View {
        alert("Bluetoothを有効にしてください", isPresented: isBluetoothDisabled) {
            Button("設定画面を開く") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            .keyboardShortcut(.defaultAction)
        } message: {}
    }
}
