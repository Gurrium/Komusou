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
    var delegate: SpeedSensorDelegate?

    // speed measurement
    private var speed: Double = 0 {
        didSet {
            delegate?.onSpeedUpdate(speed)
        }
    }
    private var previousWheelEventTime: UInt16?
    private var previousCumulativeWheelRevolutions: UInt32?
    private var speedMeasurementPauseCounter = 0 {
        didSet {
            if speedMeasurementPauseCounter > 2 {
                speed = 0
            }
        }
    }
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        BluetoothManager.shared.$speedData.sink { [unowned self] data in
            guard let data = data else { return }

            let value = [UInt8](data)
            guard (value[0] & 0b0001) > 0 else { return }

            // ref: https://www.bluetooth.com/specifications/specs/gatt-specification-supplement-5/
            if let retrieved = self.parseSpeed(from: value) {
                self.speedMeasurementPauseCounter = 0

                self.speed = retrieved
            } else {
                self.speedMeasurementPauseCounter += 1
            }
        }
        .store(in: &cancellables)
    }

    private func parseSpeed(from value: [UInt8]) -> Double? {
        precondition(value[0] & 0b0001 > 0, "Wheel Revolution Data Present Flag is not set")

        guard let wheelCircumference = delegate?.wheelCircumference else { return nil }

        let cumulativeWheelRevolutions = (UInt32(value[4]) << 24) + (UInt32(value[3]) << 16) + (UInt32(value[2]) << 8) + UInt32(value[1])
        let wheelEventTime = (UInt16(value[6]) << 8) + UInt16(value[5])

        defer {
            previousCumulativeWheelRevolutions = cumulativeWheelRevolutions
            previousWheelEventTime = wheelEventTime
        }

        guard let previousCumulativeWheelRevolutions = previousCumulativeWheelRevolutions,
              let previousWheelEventTime = previousWheelEventTime else { return nil }

        let duration: UInt16

        if previousWheelEventTime > wheelEventTime {
            duration = UInt16((UInt32(wheelEventTime) + UInt32(UInt16.max) + 1) - UInt32(previousWheelEventTime))
        } else {
            duration = wheelEventTime - previousWheelEventTime
        }

        guard duration > 0 else { return nil }

        let revolutionsPerSec = Double(cumulativeWheelRevolutions - previousCumulativeWheelRevolutions) / (Double(duration) / 1024)

        return revolutionsPerSec * Double(wheelCircumference) * 3600 / 1_000_000 // [km/h]
    }
}
