//
//  WorldView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/06.
//

import SwiftUI
import SceneKit

final class WorldView: UIViewRepresentable {
    private var box: SCNNode = {
        let box = SCNNode()
        box.geometry = SCNBox(width: 5, height: 2, length: 2, chamferRadius: 0)

        return box
    }()

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
        box.runAction(.move(to: SCNVector3(x: -20, y: 2, z: 0), duration: .zero))

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        box.addChildNode(cameraNode)
        cameraNode.runAction(.group([
            .moveBy(x: -30, y: 30, z: 0, duration: 0),
            .rotateBy(x: 0, y: -.pi / 2, z: 0, duration: 0),
            .rotateBy(x: 0, y: 0, z: -.pi / 4, duration: 0)
        ]))

        scnView.scene = scene
        scnView.showsStatistics = true
        scnView.backgroundColor = .black

        scnView.allowsCameraControl = true

        return scnView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
