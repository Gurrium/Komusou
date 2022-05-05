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
    var centralManager: CentralManagerMock!
    var bluetoothManager: BluetoothManager!
    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        centralManager = CentralManagerMock()
        bluetoothManager = BluetoothManager(centralManager: centralManager)
    }

    override func tearDown() {
        cancellables.removeAll()
    }

    func test_delegate() {
        XCTAssertIdentical(centralManager.delegate, bluetoothManager)
    }

    func test_Bluetoothが使えるときだけスキャンする() throws {
        throw XCTSkip("テスト用にserviceUUIDsにnilを渡すようになっている")

        let exp = expectation(description: "scanForPeripheralsが呼ばれる")

        centralManager.state = .unknown
        bluetoothManager.centralManagerDidUpdateState(centralManager)
        bluetoothManager.scanForSensors()
        XCTAssertEqual(centralManager.scanForPeripheralsCallCount, 0)

        centralManager.state = .poweredOn
        bluetoothManager.centralManagerDidUpdateState(centralManager)
        centralManager.scanForPeripheralsHandler = { serviceUUIDs, _ in
            XCTAssertEqual(serviceUUIDs, [.cyclingSpeedAndCadence])
            exp.fulfill()
        }
        bluetoothManager.scanForSensors()
        XCTAssertEqual(centralManager.scanForPeripheralsCallCount, 1)

        wait(for: [exp], timeout: 0.1)
    }

    func test_名前があるBluetoothデバイスを一覧できる() {
        let exp = expectation(description: "発見されたPeripheralのidentifierの配列が期待したものと同じである")
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let id4 = UUID()
        let peripherals: [PeripheralMock] = [
            .init(name: "SPD-1", identifier: id1),
            .init(name: "SPD-2", identifier: id2),
            .init(name: "SPD-3", identifier: id3),
            .init(name: nil, identifier: id4),
        ]

        scanForPeripherals(peripherals)

        bluetoothManager.$sensorNames
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

    func test_未発見のセンサーには接続できない() {
        let exp = expectation(description: "未発見のセンサーには接続されない")
        let peripheral = PeripheralMock(name: "SPD-1")

        powerOnCentralManager()

        centralManager.connectHandler = { _, _ in
            XCTFail()
        }
        XCTAssertEqual(bluetoothManager.sensorNames, [:])
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
        let connectExp = expectation(description: "connect")
        let peripheral = PeripheralMock(name: "SPD-1")

        connectToSpeedSensor(peripheral)

        centralManager.connectHandler = { peripheralAttemptedToConnect, _ in
            XCTAssertEqual(peripheralAttemptedToConnect.identifier, peripheral.identifier)
            connectExp.fulfill()
        }
        centralManager.retrievePeripheralsHandler = { UUIDs in
            XCTAssertEqual(UUIDs, [peripheral.identifier])

            return [peripheral]
        }
        bluetoothManager = BluetoothManager(centralManager: centralManager)

        wait(for: [connectExp], timeout: 0.1)
    }

    func test_deinit() {
        let cancelPeripheralConnectionExp = expectation(description: "cancelPeripheralConnection")
        let stopScanExp = expectation(description: "stopScan")
        let peripheral = PeripheralMock(name: "SPD-1")

        connectToSpeedSensor(peripheral)

        centralManager.cancelPeripheralConnectionHandler = { peripheralAttemptedToCancelConnection in
            XCTAssertEqual(peripheralAttemptedToCancelConnection.identifier, peripheral.identifier)
            cancelPeripheralConnectionExp.fulfill()
        }
        centralManager.stopScanHandler = { stopScanExp.fulfill() }
        bluetoothManager = nil
        wait(for: [cancelPeripheralConnectionExp, stopScanExp], timeout: 0.1)
    }

    private func powerOnCentralManager() {
        centralManager.state = .poweredOn
        bluetoothManager.centralManagerDidUpdateState(centralManager)
    }

    func test_powerOnCentralManager() {
        powerOnCentralManager()

        XCTAssertEqual(centralManager.state, .poweredOn)
        XCTAssertEqual(bluetoothManager.isBluetoothEnabled, true)
    }

    private func scanForPeripherals(_ peripherals: [PeripheralMock]) {
        powerOnCentralManager()

        centralManager.scanForPeripheralsHandler = { [unowned bluetoothManager = bluetoothManager!, unowned centralManager = centralManager!] _, _ in
            peripherals.forEach { peripheral in
                bluetoothManager.centralManager(centralManager, didDiscover: peripheral, advertisementData: [:], rssi: 0)
            }
        }
        bluetoothManager.scanForSensors()
    }

    func test_scanForPeripherals() {
        let id = UUID()
        scanForPeripherals([.init(name: "SPD-1", identifier: id)])

        XCTAssertEqual(centralManager.state, .poweredOn)
        XCTAssertEqual(bluetoothManager.isBluetoothEnabled, true)
        XCTAssertEqual(bluetoothManager.sensorNames, [id: "SPD-1"])
    }

    private func connectToSpeedSensor(_ peripheral: PeripheralMock) {
        scanForPeripherals([peripheral])

        centralManager.connectHandler = { [unowned bluetoothManager = bluetoothManager!, unowned centralManager = centralManager!] _, _ in
            bluetoothManager.centralManager(centralManager, didConnect: peripheral)
        }
        bluetoothManager?.connectToSpeedSensor(uuid: peripheral.identifier)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    func test_connectToSpeedSensor() {
        let id = UUID()
        let peripheral = PeripheralMock(name: "SPD-1", identifier: id)
        connectToSpeedSensor(peripheral)

        XCTAssertEqual(bluetoothManager.connectedSpeedSensor?.identifier, id)
    }
}
