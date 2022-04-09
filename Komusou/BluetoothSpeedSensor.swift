//
//  BluetoothSpeedSensor.swift
//  Komusou
//
//  Created by gurrium on 2022/03/16.
//

import Combine
import CoreBluetooth
import Foundation

final class BluetoothSpeedSensor: NSObject, SpeedSensor {
    // SpeedSensor
    var delegate: SpeedSensorDelegate? // TODO: これも@Publishedでいいのでは？

    // speed measurement
    private var speed: Double = 0 {
        didSet {
            delegate?.onSpeedUpdate(speed)
        }
    }
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        BluetoothManager.shared.$speed
            .compactMap { $0 }
            .sink { [unowned self] speed in
                self.speed = speed
            }
            .store(in: &cancellables)
    }
}
