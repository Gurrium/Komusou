//
//  PlayView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import SwiftUI

struct PlayView: View {
    @State var isSettingsPresented = false

    var body: some View {
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
//        .alert("Bluetoothを有効にしてください", isPresented: .constant(BluetoothManager.shared.isBluetoothEnabled)) {
//            // TODO: 設定画面に飛ばす
//            Button("OK") {
//                print("TODO: 設定画面に飛ばす")
//            }
//        } message: {}
    }
}

struct PlayView_Previews: PreviewProvider {
    static var previews: some View {
        PlayView()
    }
}
