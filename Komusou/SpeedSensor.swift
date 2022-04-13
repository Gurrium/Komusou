//
//  SpeedSensor.swift
//  Komusou
//
//  Created by gurrium on 2022/03/16.
//

import Foundation

protocol SpeedSensorDelegate: AnyObject {
    var wheelCircumference: Int { get }

    func onSpeedUpdate(_ speed: Double)
}

protocol SpeedSensor: AnyObject {
    var speed: Published<Double?>.Publisher! { get }
}
