//
//  PlayView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import SwiftUI

struct PlayView: View {
    @State
    var isSettingsPresented = false
    @State
    private var isBluetoothEnabled = BluetoothManager.shared.isBluetoothEnabled

    var body: some View {
        Group {
            if isBluetoothEnabled {
                ZStack(alignment: .topTrailing) {
                    WorldView(speedSensor: KomusouApp.speedSensor, cadenceSensor: KomusouApp.cadenceSensor)
                        .edgesIgnoringSafeArea(.all)
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                            .resizable()
                            .padding(8)
                            .frame(width: 44, height: 44)
                            .foregroundColor(.black)
                    }
                }
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView()
                }
            } else {
                Text("Bluetoothを有効にしてください")
                // TODO: 設定画面に飛ばす
            }
        }
        .onReceive(BluetoothManager.shared.$isBluetoothEnabled) { isBluetoothEnabled in
            self.isBluetoothEnabled = isBluetoothEnabled
        }
    }
}

struct PlayView_Previews: PreviewProvider {
    static var previews: some View {
        PlayView()
    }
}
