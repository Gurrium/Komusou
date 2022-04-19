//
//  SpeedSensor.swift
//  Komusou
//
//  Created by gurrium on 2022/03/16.
//

import Foundation

protocol SpeedSensor: AnyObject {
    var speed: Published<Double?>.Publisher! { get }
}
