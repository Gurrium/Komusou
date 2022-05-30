//
//  KomusouApp.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import Combine
import SwiftUI

// TODO:
// - Mac対応
// - i18n

@main
struct KomusouApp: App {
    static let bluetoothSpeedSensor = BluetoothSpeedSensor()
    static let mockSpeedSensor = MockSpeedSensor()

    @UIApplicationDelegateAdaptor
    private var appDelegate: AppDelegate
    @State
    private var isSettingsPresented = false
    @State
    private var isBluetoothEnabled = true
    @State
    private var speed = 0.0
    private var speedSensor: SpeedSensor {
        isBluetoothEnabled ? Self.bluetoothSpeedSensor : Self.mockSpeedSensor
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .topLeading) {
                        WorldView(speed: speed)
                            .edgesIgnoringSafeArea(.all)
                        InfoPanelView(speed: speed, cadence: 0)
                            .padding([.top, .leading])
                    }
                    .onReceive(speedSensor.speed.compactMap { $0 }) { speed in
                        self.speed = speed
                    }
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
                if !isBluetoothEnabled {
                    DemoDescriptionView()
                }
            }.onReceive(BluetoothManager.shared().$isBluetoothEnabled) { isBluetoothEnabled in
                self.isBluetoothEnabled = isBluetoothEnabled
            }
        }
    }

    private struct DemoDescriptionView: View {
        var body: some View {
            // TODO: iikanjinisuru
            VStack(spacing: 8) {
                Text("デモを表示しています")
                Text("Bluetoothを有効にしてください")
                Button("設定画面を開く") {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
            .padding()
            .background(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.gray.opacity(0.5)) // TODO: 背景色と文字色を修正する
        }
    }

    struct DemoDescriptionView_Preview: PreviewProvider {
        static var previews: some View {
            ZStack {
                GeometryReader { geometry in
                    let sideLength = geometry.size.width / 10
                    let numOfRows = Int(ceil(geometry.size.height / CGFloat(sideLength)))
                    VStack(spacing: 0) {
                        ForEach(0..<numOfRows) { i in
                            HStack(spacing: 0) {
                                ForEach(0..<10) { j in
                                    Text("\(i * 10 + j)")
                                        .foregroundColor(.red)
                                        .frame(width: sideLength, height: sideLength)
                                        .background((i + j) % 2 == 0 ? .white : .black)
                                }
                            }
                        }
                    }
                }
                DemoDescriptionView()
            }
            .ignoresSafeArea()
        }
    }
}

final class MockSpeedSensor: SpeedSensor {
    var speed: Published<Double?>.Publisher!
    @Published
    private var _speed: Double?

    init() {
        speed = $_speed

        DispatchQueue.global().async { [weak self] in
            self?.scheduleUpdate()
        }
    }

    private func scheduleUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            let speed = Double((0...60).randomElement()!) / Double((1...60).randomElement()!)
            print(speed)
            self?._speed = speed

            self?.scheduleUpdate()
        }
    }
}

final class MockCadenceSensor: CadenceSensor {
    var delegate: CadenceSensorDelegate?

    init() {
        DispatchQueue.global().async { [weak self] in
            self?.scheduleUpdate()
        }
    }

    private func scheduleUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            let cadence = 90 + Double((-20...20).randomElement()!)
            print(cadence)
            self?.delegate?.onCadenceUpdate(cadence)

            self?.scheduleUpdate()
        }
    }
}
