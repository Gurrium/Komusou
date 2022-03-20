//
//  WorldView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/06.
//

import SwiftUI
import SceneKit

final class WorldView: UIViewRepresentable {
    private let worldView: _WorldView
    private let speedSensor: SpeedSensor
    private let cadenceSensor: CadenceSensor

    init(speedSensor: SpeedSensor, cadenceSensor: CadenceSensor) {
        self.speedSensor = speedSensor
        self.cadenceSensor = cadenceSensor

        worldView = UINib(nibName: "WorldView", bundle: nil).instantiate(withOwner: nil).first as! _WorldView
        worldView.build(speedSensor: speedSensor, cadenceSensor: cadenceSensor)
    }

    func makeUIView(context: Context) -> _WorldView {
        worldView
    }

    func updateUIView(_ uiView: _WorldView, context: Context) {}
}

final class _WorldView: UIView {
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var cadenceLabel: UILabel!

    private var speedSensor: SpeedSensor!
    private var speed = 0.0 {
        didSet {
            speedLabel.text = "Speed: \(formatter.string(from: .init(value: speed))!)[km/h]"
        }
    }
    private var cadenceSensor: CadenceSensor!
    private var cadence = 0.0 {
        didSet {
            cadenceLabel.text = "Cadence: \(formatter.string(from: .init(value: cadence))!)[rpm]" // km/hと合わせてr/mにしたい気持ちもあるが一般的な表記でないので…
        }
    }
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 4

        return formatter
    }()
    private var box: SCNNode = {
        let box = SCNNode()
        box.geometry = SCNBox(width: 5, height: 2, length: 2, chamferRadius: 0)
        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue

        return box
    }()
    let boxBase = SCNNode()

    func build(speedSensor: SpeedSensor, cadenceSensor: CadenceSensor) {
        self.speedSensor = speedSensor
        self.cadenceSensor = cadenceSensor

        self.speedSensor.delegate = self
        self.cadenceSensor.delegate = self

        setupScnView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupScnView() {
        let scene = scnView.scene!

        let plane = SCNNode()
        plane.geometry = SCNFloor()
        plane.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/check.png")
        plane.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(10, 10, 0)
        plane.geometry?.firstMaterial?.diffuse.wrapS = .repeat
        plane.geometry?.firstMaterial?.diffuse.wrapT = .repeat
        scene.rootNode.addChildNode(plane)

        scene.rootNode.addChildNode(boxBase)
        boxBase.addChildNode(box)
        boxBase.runAction(.moveBy(x: 0, y: 3, z: 0, duration: 0))

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        boxBase.addChildNode(cameraNode)
        cameraNode.runAction(.group([
            .moveBy(x: -20, y: 20, z: 0, duration: 0),
            .rotateBy(x: 0, y: -.pi / 2, z: -.pi / 6, duration: 0)
        ]))

        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 100
        scnView.scene?.rootNode.light = ambientLight

        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 800
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        scnView.scene?.rootNode.addChildNode(directionalLightNode)
        directionalLightNode.runAction(.group([
            .moveBy(x: -100, y: 100, z: 0, duration: 0),
            .rotateBy(x: 0, y: -.pi / 4, z: -.pi / 4, duration: 0)
        ]))

        scnView.scene = scene
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = true

        #if DEBUG
        scnView.showsStatistics = true
        #endif
    }
}

extension _WorldView: SpeedSensorDelegate {
    var wheelCircumference: Int { 2048 }
    var movingKey: String { "movingAction" }

    func onSpeedUpdate(_ speed: Double) {
        boxBase.removeAction(forKey: movingKey)
        boxBase.runAction(.repeatForever(.moveBy(x: speed, y: 0, z: 0, duration: 1)), forKey: movingKey)

        self.speed = speed
    }
}

extension _WorldView: CadenceSensorDelegate {
    var rotatingKey: String { "rotatingAction" }

    func onCadenceUpdate(_ cadence: Double) {
        box.removeAction(forKey: rotatingKey)
        box.runAction(.repeatForever(.rotateBy(x: cadence, y: 0, z: 0, duration: 1)), forKey: rotatingKey)

        self.cadence = cadence
    }
}
