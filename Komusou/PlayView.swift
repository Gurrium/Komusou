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
    private var isBluetoothEnabled = BluetoothManager.shared().isBluetoothEnabled

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
                VStack(spacing: 16) {
                    Text("Bluetoothを有効にしてください")
                    Button("設定画面を開く") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }
            }
        }
        .onReceive(BluetoothManager.shared().$isBluetoothEnabled) { isBluetoothEnabled in
            self.isBluetoothEnabled = isBluetoothEnabled
        }
    }
}

struct PlayView_Previews: PreviewProvider {
    static var previews: some View {
        PlayView()
    }
}
