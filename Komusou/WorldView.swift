//
//  WorldView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/06.
//

import Combine
import SceneKit
import SwiftUI

struct AltWorldView: View {
    @Binding
    var isBluetoothEnabled: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            WorldView()
            InfoPanelView(speed: <#T##Binding<Double>#>)
                .padding([.top, .leading])
        }
    }
}

struct InfoPanelView: View {
    private static let speedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 3
        formatter.maximumSignificantDigits = 3

        return formatter
    }()

    private static let cadenceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 2
        formatter.maximumSignificantDigits = 3

        return formatter
    }()

    var speed: Double
    var cadence: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(Self.speedFormatter.string(from: .init(value: speed))!)[km/h]")
            Text("\(Self.cadenceFormatter.string(from: .init(value: cadence))!)[rpm]" )
        }
        .foregroundColor(.white)
        .font(.headline)
        .padding()
        .background(.gray)
    }
}

struct AltWorldView_Preview: PreviewProvider {
    static var previews: some View {
        AltWorldView(isBluetoothEnabled: .constant(true))
            .previewLayout(.sizeThatFits)
    }
}

struct WorldView: UIViewRepresentable {
    private let worldView: _WorldView

    init(speedSensor: SpeedSensor, cadenceSensor: CadenceSensor) {
        worldView = UINib(nibName: "WorldView", bundle: nil).instantiate(withOwner: nil).first as! _WorldView
        worldView.build(speedSensor: speedSensor, cadenceSensor: cadenceSensor)
    }

    func makeUIView(context _: Context) -> _WorldView {
        worldView
    }

    func updateUIView(_: _WorldView, context _: Context) {}
}

final class _WorldView: UIView {
    @IBOutlet var scnView: SCNView!

    private var speedSensor: SpeedSensor!
    private var speed = 0.0
    private let movingKey = "movingAction"

    // TODO: スピードに揃える
//    private var cadenceSensor: CadenceSensor!
//    private var cadence = 0.0 {
//        didSet {
//            controlPanel.render(speed: speed, cadence: cadence)
//        }
//    }

    private var box: SCNNode = {
        let box = SCNNode()
        box.geometry = SCNBox(width: 5, height: 2, length: 2, chamferRadius: 0)
        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue

        return box
    }()
    private var cancellables = Set<AnyCancellable>()

    let boxBase = SCNNode()

    func build(speedSensor: SpeedSensor, cadenceSensor _: CadenceSensor) {
        self.speedSensor = speedSensor
//        self.cadenceSensor = cadenceSensor

        self.speedSensor.speed
            .compactMap { $0 }
            .sink { [unowned self] speed in
                boxBase.removeAction(forKey: movingKey)
                boxBase.runAction(.repeatForever(.moveBy(x: speed, y: 0, z: 0, duration: 1)), forKey: movingKey)
            }
            .store(in: &cancellables)
//        self.cadenceSensor.delegate = self

        setupViews()
    }

    private func setupViews() {
        setupScnView()
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
            .rotateBy(x: 0, y: -.pi / 2, z: -.pi / 6, duration: 0),
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
            .rotateBy(x: 0, y: -.pi / 4, z: -.pi / 4, duration: 0),
        ]))

        scnView.scene = scene
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = true

        #if DEBUG
            scnView.showsStatistics = true
        #endif
    }
}

// extension _WorldView: CadenceSensorDelegate {
//    var rotatingKey: String { "rotatingAction" }
//
//    func onCadenceUpdate(_ cadence: Double) {
//        box.removeAction(forKey: rotatingKey)
//        box.runAction(.repeatForever(.rotateBy(x: cadence, y: 0, z: 0, duration: 1)), forKey: rotatingKey)
//
//        self.cadence = cadence
//    }
// }
