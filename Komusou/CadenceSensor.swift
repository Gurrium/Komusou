//
//  CadenceSensor.swift
//  Komusou
//
//  Created by gurrium on 2022/03/17.
//

import Foundation

protocol CadenceSensorDelegate: AnyObject {
    func onCadenceUpdate(_ speed: Double)
}

protocol CadenceSensor: AnyObject {
    var delegate: CadenceSensorDelegate? { get set }
}
