//
//  WorldView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/06.
//

import SwiftUI
import SceneKit

final class WorldView: UIViewRepresentable {
    private var speedSensor: SpeedSensor
    private var box: SCNNode = {
        let box = SCNNode()
        box.geometry = SCNBox(width: 5, height: 2, length: 2, chamferRadius: 0)

        return box
    }()

    init(speedSensor: SpeedSensor) {
        self.speedSensor = speedSensor
        self.speedSensor.delegate = self
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()

        // create a new scene
        let scene = SCNScene(named: "art.scnassets/world.scn")!

        let plane = SCNNode()
        plane.runAction(.rotateBy(x: -.pi / 2, y: 0, z: 0, duration: .zero))
        plane.geometry = SCNPlane(width: 50, height: 50)
        plane.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/check.png")
        plane.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(10, 10, 0)
        plane.geometry?.firstMaterial?.diffuse.wrapS = .repeat
        plane.geometry?.firstMaterial?.diffuse.wrapT = .repeat
        scene.rootNode.addChildNode(plane)

        scene.rootNode.addChildNode(box)
        print(box.pivot)
        box.pivot = SCNMatrix4MakeTranslation(10, 0, 0)
        print(box.pivot)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.runAction(.group([
            .moveBy(x: 0, y: 70, z: 0, duration: 0),
            .rotateBy(x: -.pi / 2, y: 0, z: 0, duration: 0)
        ]))

        scnView.scene = scene
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = true

        #if DEBUG
        scnView.showsStatistics = true
        #endif

        return scnView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

extension WorldView: SpeedSensorDelegate {
    var wheelCircumference: Int { 2048 }

    func onSpeedUpdate(_ speed: Double) {
        box.removeAllActions()
        box.runAction(.repeatForever(.rotateBy(x: 0, y: speed, z: 0, duration: 1)))
    }
}
