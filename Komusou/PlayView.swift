////
////  PlayView.swift
////  Komusou
////
////  Created by gurrium on 2022/03/05.
////
//
// import SwiftUI
//
// struct PlayView: View {
//    static let bluetoothSpeedSensor = BluetoothSpeedSensor()
//    static let mockSpeedSensor = MockSpeedSensor()
//
//    @State
//    var isSettingsPresented = false
//    @State
//    private var isBluetoothEnabled = true
//
//    var body: some View {
//        ZStack {
//            ZStack(alignment: .topTrailing) {
//                AltWorldView(speedSensor: isBluetoothEnabled ? Self.bluetoothSpeedSensor : Self.mockSpeedSensor)
//                Button {
//                    isSettingsPresented = true
//                } label: {
//                    Image(systemName: "gearshape")
//                        .resizable()
//                        .padding(8)
//                        .frame(width: 44, height: 44)
//                        .foregroundColor(.black)
//                }
//            }
//            .sheet(isPresented: $isSettingsPresented) {
//                SettingsView()
//            }
//            if !isBluetoothEnabled {
//                VStack(spacing: 8) {
//                    Text("デモを表示しています")
//                    Text("Bluetoothを有効にしてください")
//                    Button("設定画面を開く") {
//                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
//                    }
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .background(.gray.opacity(0.5)) // TODO: 背景色と文字色を修正する
//            }
//        }.onReceive(BluetoothManager.shared().$isBluetoothEnabled) { isBluetoothEnabled in
//            self.isBluetoothEnabled = isBluetoothEnabled
//        }
//    }
// }
//
// struct PlayView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlayView()
//    }
// }
