//
//  BluetoothManagerTest.swift
//  KomusouTests
//
//  Created by gurrium on 2022/04/20.
//

import Combine
import CoreBluetooth
@testable import Komusou
import XCTest

class BluetoothManagerTest: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
    }

    func test_Bluetoothが使えるときだけスキャンする() {
        let centralManager = CentralManagerMock()
        let bluetoothManager = BluetoothManager(centralManager: centralManager)

        centralManager.state = .unknown
        bluetoothManager.centralManagerDidUpdateState(centralManager)
        bluetoothManager.startScanningSensors()
        XCTAssertEqual(centralManager.scanForPeripheralsCallCount, 0)

        centralManager.state = .poweredOn
        bluetoothManager.centralManagerDidUpdateState(centralManager)
        bluetoothManager.startScanningSensors()
        XCTAssertEqual(centralManager.scanForPeripheralsCallCount, 1)
    }

    func test_名前があるBluetoothデバイスを一覧できる() {
        let exp = expectation(description: "発見されたPeripheralのidentifierの配列が期待したものと同じであることがテストされる")

        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let id4 = UUID()
        let peripherals: [Peripheral] = [
            PeripheralMock(name: "SPD-1", identifier: id1),
            PeripheralMock(name: "SPD-2", identifier: id2),
            PeripheralMock(name: "SPD-3", identifier: id3),
            PeripheralMock(name: nil, identifier: id4),
        ]
        let centralManager = CentralManagerMock()
        let bluetoothManager = BluetoothManager(centralManager: centralManager)
        XCTAssertIdentical(centralManager.delegate, bluetoothManager)
        centralManager.state = .poweredOn
        bluetoothManager.centralManagerDidUpdateState(centralManager)

        centralManager.scanForPeripheralsHandler = { _, _ in
            peripherals.forEach { peripheral in
                bluetoothManager.centralManager(centralManager, didDiscover: peripheral, advertisementData: [:], rssi: 0)
            }
        }
        bluetoothManager.startScanningSensors()

        bluetoothManager.$discoveredNamedPeripheralNames
            .sink { actual in
                let expected = [
                    id1: "SPD-1",
                    id2: "SPD-2",
                    id3: "SPD-3",
                ]
                XCTAssertEqual(actual, expected)
                exp.fulfill()
            }
            .store(in: &cancellables)
        wait(for: [exp], timeout: 0.1)
    }

    func test_発見済みのセンサーに接続できる() {
        let exp = expectation(description: "期待したセンサーに接続されたことがテストされる")

        let id = UUID()
        let peripheral: Peripheral = PeripheralMock(name: "SPD-1", identifier: id)
        let centralManager = CentralManagerMock()
        let bluetoothManager = BluetoothManager(centralManager: centralManager)
        XCTAssertIdentical(centralManager.delegate, bluetoothManager)
        centralManager.state = .poweredOn
        bluetoothManager.centralManagerDidUpdateState(centralManager)

        centralManager.scanForPeripheralsHandler = { _, _ in
            bluetoothManager.centralManager(centralManager, didDiscover: peripheral, advertisementData: [:], rssi: 0)
        }
        bluetoothManager.startScanningSensors()

        centralManager.connectHandler = { peripheralThatIsAttemptedToConnect, _ in
            XCTAssertEqual(peripheralThatIsAttemptedToConnect.identifier, peripheral.identifier)
            bluetoothManager.centralManager(centralManager, didConnect: peripheral)
        }
        bluetoothManager.connectToSpeedSensor(uuid: peripheral.identifier)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure:
                    XCTFail()
                case .finished:
                    exp.fulfill()
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 0.1)
    }

    func test_未発見のセンサーには接続できない() {
        let exp = expectation(description: "未発見のセンサーには接続できないことがテストされる")

        let id = UUID()
        let peripheral: Peripheral = PeripheralMock(name: "SPD-1", identifier: id)
        let centralManager = CentralManagerMock()
        let bluetoothManager = BluetoothManager(centralManager: centralManager)
        XCTAssertIdentical(centralManager.delegate, bluetoothManager)
        centralManager.state = .poweredOn
        bluetoothManager.centralManagerDidUpdateState(centralManager)

        centralManager.connectHandler = { _, _ in
            XCTFail()
        }
        XCTAssertEqual(bluetoothManager.discoveredNamedPeripheralNames, [:])
        bluetoothManager.connectToSpeedSensor(uuid: peripheral.identifier)
            .sink { result in
                switch result {
                case .failure:
                    exp.fulfill()
                default:
                    XCTFail()
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 0.1)
    }

    func test_初期化時に前回接続したセンサーと接続する() {
        let exp = expectation(description: "期待したセンサーに接続されたことがテストされる")

        let id = UUID()
        let peripheral: Peripheral = PeripheralMock(name: "SPD-1", identifier: id)
        let centralManager = CentralManagerMock()
        var bluetoothManager = BluetoothManager(centralManager: centralManager)
        XCTAssertIdentical(centralManager.delegate, bluetoothManager)
        centralManager.state = .poweredOn
        bluetoothManager.centralManagerDidUpdateState(centralManager)
        centralManager.scanForPeripheralsHandler = { _, _ in
            bluetoothManager.centralManager(centralManager, didDiscover: peripheral, advertisementData: [:], rssi: 0)
        }
        bluetoothManager.startScanningSensors()
        centralManager.connectHandler = { _, _ in
            bluetoothManager.centralManager(centralManager, didConnect: peripheral)
        }
        bluetoothManager.connectToSpeedSensor(uuid: peripheral.identifier)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure:
                    XCTFail()
                default:
                    break
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        centralManager.connectHandler = { peripheralAttemptedToConnect, _ in
            XCTAssertEqual(peripheralAttemptedToConnect.identifier, peripheral.identifier)
            exp.fulfill()
        }
        centralManager.retrievePeripheralsHandler = { UUIDs in
            XCTAssertEqual(UUIDs, [peripheral.identifier])

            return [peripheral]
        }
        bluetoothManager = BluetoothManager(centralManager: centralManager)

        wait(for: [exp], timeout: 0.1)
    }
}
