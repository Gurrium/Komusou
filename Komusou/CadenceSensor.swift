//
//  CadenceSensor.swift
//  Komusou
//
//  Created by gurrium on 2022/03/17.
//

import Foundation

protocol CadenceSensor: AnyObject {
    var cadence: Published<Int?>.Publisher! { get }
}
