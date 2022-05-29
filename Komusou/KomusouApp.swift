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
                    VStack(spacing: 8) {
                        Text("デモを表示しています")
                        Text("Bluetoothを有効にしてください")
                        Button("設定画面を開く") {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.gray.opacity(0.5)) // TODO: 背景色と文字色を修正する
                }
            }.onReceive(BluetoothManager.shared().$isBluetoothEnabled) { isBluetoothEnabled in
                self.isBluetoothEnabled = isBluetoothEnabled
            }
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
